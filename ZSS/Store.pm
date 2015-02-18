package ZSS::Store;

use strict;
use warnings;

use Digest::MD5 qw (md5_hex);
use File::Util qw(escape_filename);
use File::Path qw(make_path);

sub new {
  my $class = shift;

  # TODO: read from config
  my $self = {storagepath => shift};

  bless $self, $class;
}

sub get_path {
  my $self = shift;
  my $key = shift;

  my $dirname = md5_hex($key);

  my $dir = $self->{storagepath} . substr($dirname, 0, 1) . "/" . $dirname ."/";

  return $dir;
}

sub get_filename {
  my $self = shift;
  my $key = shift;

  return escape_filename($key, '_');
}

sub get_filepath {
  my $self = shift;
  my $key = shift;

  return $self->get_path($key) . $self->get_filename($key);
}

sub store_file {
  my $self = shift;
  my $key = shift;
  my $data = shift;

  my $dir = $self->get_path($key);
  my $file = $self->get_filename($key);

  make_path($dir);
  #$self->log($filepath);
 
 # TODO: check if file already exists
  # what to do then? overwrite?

  open(my $fh, '>:raw', $dir.$file);
  print $fh ($data);
  close($fh);
 # TODO: add another file with the metadata (Content-MD5, Content-Type, ...)

}

sub check_exists{
  my $self = shift;
  my $key = shift;
  
  my $path = $self->get_filepath($key);
  unless (-e $path){
    return 0;
  }
  return 1;
}

sub retrieve_file {
  my $self = shift;
  my $key = shift;

  unless($self->check_exists($key)){
    return undef;
  }
  my $path = $self->get_filepath($key);
  open(my $fh, '<:raw', $path);
  return $fh;
}

sub get_size{
  my $self = shift;
  my $key = shift;

  my $path = $self->get_filepath($key);
  
  unless (-e $path) {
   return 0;
  }
  my $size = -s $path;
  return $size;
}

sub link_files{
  my $self = shift;
  my $source_key = shift;
  my $destination_key = shift;

  my $source_path = $self->get_filepath($source_key);
  my $destination_dir = $self->get_path($destination_key);
  my $destination_path = $self->get_filepath($destination_key);

  make_path($destination_dir);

  return link($source_path, $destination_path);
}

sub delete_file{
  my $self = shift;
  my $key = shift;

  my $dir = $self->get_path($key);
  my $file = $self->get_filename($key);

  unless (unlink($dir.$file)) {
    return 1;
  }
  return rmdir($dir);
}

1;
