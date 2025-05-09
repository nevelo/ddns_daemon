# ddns_daemon
A small ddns refresh bash script + cron job that creates the necessary
con and log files to call a cPanel-style capability URL.

The refresher script defaults to running every 10 minutes and looks
for your unique capability URL under /etc/ddns_sync.conf.

Syntax:
	sudo ./ddns_installer.sh


