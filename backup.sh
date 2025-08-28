filename="BACKUP/cm"_$(date +"%s").bak
echo "FILE: "$filename
cd ~
cd "Backup"
echo "STATUS: BACKUP"
PGPASSWORD="postgres" pg_dump -U postgres -f $filename -d cantik_mart
echo "STATUS: DONE"
exit