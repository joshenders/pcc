#!/bin/bash

printf "Content-Type: text/html\r\n\r\n"

cat << EOF
<!doctype html>
    <html>
    <head>
        <link href="data:image/x-icon;base64,AAABAAEAEBAAAAAAAABoBQAAFgAAACgAAAAQAAAAIAAAAAEACAAAAAAAAAEAAAAAAAAAAAAAAAEAAAAAAAAAAAAAFBSQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQEBAAAAAAAAAAAAAAEBAQEBAQEBAAAAAAAAAAEBAQAAAAABAQEAAAAAAAABAQAAAAAAAAEBAAAAAAABAQAAAAAAAAAAAQEAAAAAAQEAAAAAAAAAAAEBAAAAAAEBAAAAAAAAAAABAQAAAAABAQAAAAEBAAAAAQEAAAAAAQEAAAABAQAAAAEBAAAAAAABAQAAAQEAAAEBAAAAAAAAAQEBAAEBAAEBAQAAAAAAAAABAQABAQABAQAAAAAAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//AAD//wAA/D8AAPAPAADjxwAA5+cAAM/zAADP8wAAz/MAAM5zAADOcwAA5mcAAOJHAADyTwAA/n8AAP//AAA=" rel="icon" type="image/x-icon" /> 
        <title>Plex Client Control</title>
        <style type="text/css">
            * {
                margin: 0px 0px 0px 1px;
                padding: 0px;
            }

            body {
                background-color: #1a1a1a;
                font-family: monaco;
                font-size: 9pt;
            }

            p {
                color: #9d9d9d;
            }

            p.error {
                color: #ff1a1a;
            }

            input {
                color: #000;
                margin-top: 10px;
            }

            span {
                color: #9d9d9d;                            
            }

            pre {
                color: #ffc61a;
                margin-top: 10px;
                width: 640px;
                white-space: pre-wrap;
            }
        </style>
        <script>
            XMLHttpRequest.onreadystatechange = function() {
                if (XMLHttpRequest.readyState == 4 && XMLHttpRequest.status == 200) {
                    document.getElementById("log").innerHTML = XMLHttpRequest.responseText;
                }

                XMLHttpRequest.open("GET","test.txt",true);
                XMLHttpRequest.send();
            }
        </script>
    </head>
    <body>
EOF

pid="$(ps -ax -o pid,comm | awk '/Plex$/ { print $1 }')"

function stop() {
    if [[ -n "$pid" ]]; then # plex running
        if [[ "$debug" == '1' ]]; then
            printf "<p>Stopping Plex[$pid]...</p>"
        else
            printf '<p>Stopping Plex...</p>'
        fi

        killall Plex
        sleep 1 # race condition. Plex takes a moment to terminate
    fi
}

function start() {
    printf '<p>Starting Plex...</p>'
    printf '<p class="error">'
    open -a Plex.app 2>&1 # redirection is useful for debugging 
    printf '</p>'
}

if [[ -n "$QUERY_STRING" && "$(tr '&' '\n' <<< $QUERY_STRING | awk -F= '/debug/ { print $2 }')" == '1' ]]; then # GET ?debug=1
    debug=1
fi

if [[ -n "$QUERY_STRING" && "$(tr '&' '\n' <<< $QUERY_STRING | awk -F= '/restart/ { print $2 }')" == '1' ]]; then # GET ?restart=1 
    if [[ "$debug" == '1' ]]; then
        printf "<p>Restarting Plex[$pid]...</p>"
    else
        printf '<p>Restarting Plex...</p>'
    fi
    stop
    start

    # new pid
    pid="$(ps -ax -o pid,comm | awk '/Plex$/ { print $1 }')"
fi

if [[ -n "$pid" ]]; then # plex running
    if [[ "$debug" == '1' ]]; then
        printf "<p>Plex[$pid] is running</p>"
    else
        printf '<p>Plex is running</p>'
    fi

    printf '<form><input type="hidden" name="restart" value="1" /><input type="submit" value="Restart Plex" />'

    if [[ "$debug" == '1' ]]; then
        printf '<input type="checkbox" name="debug" value="1" checked /><span>debug</span>'
    else
        # annoying browser quirk mandates newlines and/or spaces here
        cat << EOF
        <input type="checkbox" name="debug" value="1" />
        <span>debug</span>
EOF
    fi

    printf '</form>'
else
    start
fi

if [[ "$debug" == '1' ]]; then
    printf '<pre>'
    env
    printf '</pre>'
fi

printf '</body></html>'
