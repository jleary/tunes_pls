#! /usr/bin/perl

# Written by:   [John Leary](git@jleary.cc)
# Date Created: 31 Oct 2018

use strict;
use warnings;
use Mac::iTunes::Library;
use Mac::iTunes::Library::XML;
use Mac::iTunes::Library::Playlist;
use TryCatch;
use POSIX qw/ceil/;
use Encode;
use URI::Escape;
use File::Copy;
use File::Spec;
use Getopt::Long;

binmode(STDOUT, ":utf8");
&tui;


my $library;  
my %playlists;
my %playlist_tree;
my %persistent_id_map;


&tui;

sub tui{
    my $in_dir              ='';
    my $out_dir             ='';
    my $sub                 ='';
    my $selected_playlists  ='';
    my $type                ='';
    my $export_protected    ='';
    GetOptions( 'in=s'        =>\$in_dir,
                'out:s'       =>\$out_dir,
                'action=s'    =>\$sub,
                'playlists:s' =>\$selected_playlists,
                'type:s'      =>\$type,
                'export_protectd:s' =>\$export_protected,
    );
    if($sub eq 'list'){
        #Set shared vars 
        &init_vars($in_dir);
        &print_playlists(\@{$playlist_tree{'roots'}});
    }elsif($sub eq 'export'){
        my @s = split /,/, $selected_playlists;
        $export_protected = '' if lc $export_protected !~ /(y(|es)|true)/;
        &export(selected_playlists=>\@s,export_to=>$type,in_dir=>$in_dir,out_dir=>$out_dir);
    }else{
        &usage;
    }
    exit;
    
}

sub usage{

    print <<EOF;
FLAGS:
--in               - The directory in which the iTunes Music Library.xml file and iTunes Music directory live.
--out              - The directory to which the playlist files/music will be exported to.
--action           - Either `list` to get a listing of playlists and their corresponding ID numbers
                      or `export` to export to the out directory.
--playlists        - A comma delimited list of playlist ids to be exported.
--type             - The playlist format to be exported (ether pls or m3u).
--export_protected - Either "Yes" or "True" to export FairPlay DRM encrypted files or anything else to not export them

An example usage would be as follows:

./tunes_pls.pl --in ~/Music/iTunes/ --action list #To List 
./tunes_pls.pl --in ~/Music/iTunes/ --action export --type pls --out /tmp/ --playlists 6D65D1901B5A9E3B,A212534145F9BE30 #To Export
EOF

}


sub init_vars{
    $library   = Mac::iTunes::Library::XML->parse("$_[0]/iTunes Music Library.xml") or die "Could Not Open Library"; 
    %playlists = $library->playlists();
    $persistent_id_map{$playlists{$_}->{'Playlist Persistent ID'}} = $_ foreach keys %playlists; 
    (%playlist_tree) = &build_playlist_tree($library);

}

sub print_playlists{
    my($arr,$level)=@_;
    $level = 1 if !defined $level;
    foreach(@{$arr}){
        print " " x $level;
        print $playlists{$_}->playlistPersistentID," -> ",$playlists{$_}->name,"\n";
        &print_playlists(\@{$playlist_tree{$_}},$level+1,) if defined $playlist_tree{$_};
    }
}

sub build_playlist_tree{
    my %out;
    # Initial loop
    foreach(keys %playlists){
        my $pls_id=$_;
        #1. Record Roots
        #2. Record Parent->Child Relationships
        if(defined $playlists{$_}->{'Parent Persistent ID'}){
           push @{$out{$persistent_id_map{$playlists{$_}->{'Parent Persistent ID'}}}},$_;
        }else{
           push @{$out{'roots'}}, $_; #Root
        }
    }
    #Sort arrays in alphabetical order
    foreach(keys %out){
       @{$out{$_}} = sort{$playlists{$a}->name cmp $playlists{$b}->name} @{$out{$_}};
    }
    return(%out);
}

#&export iterates through the selected playlists and passes their items to 
#a playlist exporting function.
#Usage:
#    export(selected_playlists=>\@array,
#           export_protected=>1 or 0
#           export_to=>\&export function,
#           path=> path of playlist and music)


sub export{
    my %opt = @_;
    my $export_protected = (defined $opt{'export_protected'} && $opt{'export_protected'} == 1) ? 1:0;
    my %handlers = (
        pls =>\&export_to_pls,
        m3u =>\&export_to_m3u
    );
    my $handler = $handlers{lc $opt{'export_to'}} or die "Invalid Export Function.  Please specify a playlist format of pls or m3u with the --type flag";
    print "Please use the --playlists flag along with a comma delimited list of playlists\n" and exit 1 if scalar @{$opt{'selected_playlists'}} == 0;
    print "Please specify an export directory with the --out flag\n" and exit 2 if $opt{'out_dir'} eq ''; 

    &init_vars($opt{'in_dir'});

    foreach (@{$opt{'selected_playlists'}}) {
        $_ = $persistent_id_map{$_};
        try{
            $playlists{$_}->name;
            $playlists{$_}->items;
        }catch{
            warn "Null Playlist Contents or Title" and next;
        }
        my $playlist_path = $playlists{$_}->name.".$opt{'export_to'}";
        $playlist_path =~ s/(\/|\\)/-/g;
        $handler->( $playlists{$_},
                    $opt{'in_dir'},
                    File::Spec->rel2abs($opt{'out_dir'}),
                    $playlist_path,
                    $export_protected);
    }
}

sub export_to_pls{
    my ($playlist,$in_dir,$out_dir,$pls_path,$export_protected) = @_;
    my @items=$playlist->items;
    open(my $pls,'+>',"$out_dir/$pls_path") or die "Could not open pls to write.";

    binmode($pls,':utf8');

    my $music_folder = $library->musicFolder();

    print $pls "[playlist]\n";
    my $i = 0;
    foreach (; $i < scalar @items; $i++){
        next if($items[$i]->kind =~ /^Protected/ && !$export_protected);
        # Handle file location
        my $location = $items[$i]->location;
        if(length $location >= length $music_folder && substr($location,0,(length $music_folder)) eq $music_folder){
            $location = substr($location,length $music_folder,);
        }
        $location = uri_unescape($location);
        $location = Encode::decode('utf-8',$location) if Encode::decode('utf-8',$location);
        # Handle Length
        my $length = -1;
        $length = ceil($items[$i]->totalTime/1000) if defined $items[$i]->totalTime;
        print $pls "File"  , $i+1, "=", $location,"\n";
        print $pls "Title" , $i+1, "=", $items[$i]->name,"\n";
        print $pls "Length", $i+1, "=", $length  ,"\n";
        &copy_path($in_dir,$out_dir,$location);
    }
    print $pls "NumberOfEntries=$i\n";
    print $pls "Version=2\n\n";

    close $pls;

}
sub export_to_m3u{
    my ($playlist,$in_dir,$out_dir,$m3u_path,$export_protected) = @_;
    my @items=$playlist->items;
    open(my $m3u,'+>',"$out_dir/$m3u_path") or die "Could not open m3u to write.";
    binmode($m3u,':utf8');

    my $music_folder = $library->musicFolder();

    print $m3u "#EXTM3U\n";
    foreach(@items){
        # Handle file location
        next if($_->kind =~ /^Protected/ && !$export_protected);
        my $location = $_->location;
        if(length $location >= length $music_folder && substr($location,0,(length $music_folder)) eq $music_folder){
            $location = substr($location,length $music_folder,);
        }
        $location = uri_unescape($location);
        $location = Encode::decode('utf-8',$location) if Encode::decode('utf-8',$location);
        # Handle Length
        my $length = -1;
        $length = ceil($_->totalTime/1000) if defined $_->totalTime;
        print $m3u "#EXTINF:",$length," ",$_->artist," - ",$_->name,"\n";
        print $m3u "$location\n";
        &copy_path($in_dir,$out_dir,$location);
    }
    close $m3u;
}

sub copy_path{
    my ($in_dir,$out_dir,$location) = @_;
    my @dirs = split /\//,$location;
    my $file = pop @dirs;
    chdir $out_dir;
    print "$location already exists.\n" and return if -e $location;
    foreach(@dirs){
        mkdir $_ if(!-d $_);
        chdir $_;
    }
    print "$location\n";
    copy("$in_dir/iTunes Music/$location",$file) or warn "Warning: $! - $location" ;
    chdir $out_dir;
}
