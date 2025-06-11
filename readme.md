## HOLLYWOOD
```
RUN export TZ=Europe/Paris && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo 'keyboard-configuration keyboard-configuration/layoutcode string fr' > /tmp/debconf-selections && \
    echo "hollywood hollywood/region select $TZ" >> /tmp/debconf-selections && \
    debconf-set-selections /tmp/debconf-selections && \
    rm -f /tmp/debconf-selections

RUN apt install -y --no-install-recommends hollywood
```