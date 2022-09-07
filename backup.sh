filename="$USER"_$(date +"%s").bak
echo "FILE: "$filename
cd ~
cd "Backup"
echo "STATUS: BACKUP"
PGPASSWORD="postgres" pg_dump -U postgres -f $filename -d jayamakmur
echo "STATUS: DONE"
exit