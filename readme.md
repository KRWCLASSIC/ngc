# NGC (Nginx Configurator)

Linux CLI tool to simplify nginx domain configuration.

## Yapping

I made this tool because as I started hosting more and more things on my domain, I ran into the problem of managing Nginx configs and symlinks. This program makes it a bit easier by automating some of the work.

> `ngc` defaults to `/etc/nginx/...` directory, so if you're using a different one, change the first two lines of the script.

## Usage

`~# ngc`

```text
Usage:
  ngc <domain>       Edit or create Nginx config for domain
  ngc run            Link all, test once, and reload Nginx
  ngc -r <domain>    Remove domain config and symlink
  ngc -l             List all domains and their status
```

## Instalation

1. Copy ngc.sh contents.

2. `sudo nano /usr/local/bin/ngc`

3. `sudo chmod +x /usr/local/bin/ngc`

4. You can now use `ngc` in your terminal!

## TODO / Future

- Backup system

## License

idk, MIT License. it's a bash script bruh.
