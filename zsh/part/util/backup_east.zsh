#!env zsh

set -e

backup_east() {
  local remote_dev='\\kyohnas\east'
  local remote_mount='/mnt/z'
  local remote_dir='/mnt/z/'

  local ssd_dev='G:'
  local ssd_mount='/mnt/g'
  local ssd_dir='/mnt/g/east/'

  # Check if the remote mount is available
  if ! mountpoint -q "$remote_mount"; then
    echo "Mounting remote device..."
    mkdir -p "$remote_mount"
    sudo mount -t drvfs "$remote_dev" "$remote_mount"
  fi
  # Check if the SSD mount is available
  if ! mountpoint -q "$ssd_mount"; then
    echo "Mounting SSD device..."
    mkdir -p "$ssd_mount"
    sudo mount -t drvfs "$ssd_dev" "$ssd_mount"
  fi

  # Perform the backup
  echo "Starting backup from $remote_dir to $ssd_dir..."
  rsync --archive --omit-dir-times --verbose --recursive --exclude='trashbox' "$remote_dir/" "$ssd_dir/"
}
