# ansible-backup-etc
* * *

## Description
Makes a local backup of specified folders to /var/backups/system folder.

It may be specified folders to backup and days retention. 

Work is done by a Bash script, this role only copies the script and sets the cron entry.

## Variables

Optional:
- _backup_etc_paths_: list of paths to be included. Full path is required (['/etc', [/var/spool/cron] if not specified).
- _backup_etc_retain_: integer. Days to retain (7 if not specified).
