#!/bin/bash
DIRECTORY="/dev/serial/by-id"
Serial_port=""
counter=0
FORCE_CONFIG=0

Switching_mode() {
    PRODUCT_NAME=$(cat "$device_dir/product")
    MANUFACTURER=$(cat "$device_dir/manufacturer")
    SERIAL_NUMBER=$(cat "$device_dir/serial")

    if [ "$SERIAL_NUMBER" == "" ]; then
        Serial="usb-${MANUFACTURER}_${PRODUCT_NAME}"
    else
        Serial="usb-${MANUFACTURER}_${PRODUCT_NAME}_$SERIAL_NUMBER"
    fi

    for file in $(ls "$DIRECTORY" | grep "$Serial" | sort); do
        if [ "$counter" -eq 2 ]; then
            Serial_port=$file
            echo "Serial_port:$Serial_port"
            break
        fi
        counter=$((counter + 1))
    done
}

function RG200U_config() {
    DEV_NAME=RG200U
    device_dir=$1
    echo "This is a $DEV_NAME module!"
    for interface in ${device_dir}/*/net/*; do
        name=$(basename $interface)
        echo "name:$name"
    done
    if [ ! -e "/sys/class/net/$name" ] || [ "$FORCE_CONFIG" = "1" ] ; then
        Switching_mode "$device_dir"
        if [ -e $DIRECTORY/$Serial_port ] || [ "$FORCE_CONFIG" = "1" ] ; then
            echo -e "AT+QCFG=\"usbnet\",1" >$DIRECTORY/$Serial_port
            echo -e "AT+QCFG=\"nat\",0" >$DIRECTORY/$Serial_port
            echo -e "AT+QNWPREFCFG=\"mode_pref\",AUTO" >$DIRECTORY/$Serial_port
            echo -e "AT+QNETDEVCTL=1,3,1" >$DIRECTORY/$Serial_port
            echo -e "AT+CFUN=1,1" >$DIRECTORY/$Serial_port
            sleep 1
        else
            echo "The Serial_port not found!!!"
        fi
    else
        echo "This is $DEV_NAME Connection test"
        ping -c 2 -W 3 -I $name 8.8.8.8
        if [ ! "$?" == "0" ]; then
            echo "$DEV_NAME Connect faile!!!"
            Switching_mode "$device_dir"
            if [ -e $DIRECTORY/$Serial_port ]; then
                echo -e "AT+QNETDEVCTL=1,3,1" >$DIRECTORY/$Serial_port
                sleep 1
            else
                echo "The Serial_port not found!!!"
            fi
        else
            echo "$DEV_NAME Connect success!"
            exit 1
        fi
    fi
}

case $1 in
	force)
        FORCE_CONFIG=1
        ;;
esac

for device_dir in /sys/bus/usb/devices/*; do
    if [ -e "$device_dir/idProduct" ]; then
        product_id=$(cat "$device_dir/idProduct")

        if [ "$product_id" = "6002" ] || [ "$product_id" = "6001" ] || [ "$product_id" = "6005" ]; then
            echo "This is a EC200 module!"
            for interface in ${device_dir}/*/net/*; do
                name=$(basename $interface)
                echo "name:$name"
            done

            if [ ! -e "/sys/class/net/$name" ]; then
                echo "$name not found!!!"
                Switching_mode "$device_dir"
                if [ -e $DIRECTORY/$Serial_port ]; then
                    echo -e "AT+QCFG=\"usbnet\",1" >$DIRECTORY/$Serial_port
                    sleep 1
                    /usr/bin/quectel-CM >>/tmp/4G.log 2>&1 &
                else
                    echo "The Serial_port not found!!!"
                fi
            else
                echo "This is EC200 Connection test"
                ping -c 2 -W 3 -I $name 8.8.8.8
                if [ ! "$?" == "0" ]; then
                    echo "EC200 Connect faile!!!"
                    Switching_mode "$device_dir"
                    if [ -e $DIRECTORY/$Serial_port ]; then
                        #echo -e "AT+QCFG=\"usbnet\",1" > $DIRECTORY/$Serial_port
                        sleep 1
                        /usr/bin/quectel-CM >>/tmp/4G.log 2>&1 &
                    else
                        echo "The Serial_port not found!!!"
                    fi

                else
                    echo "EC200 Connect success!"
                    exit 1
                fi
            fi
        fi

        if [ "$product_id" = "0125" ]; then
            echo "This is a EC20 module!"
            for interface in ${device_dir}/*/net/*; do
                name=$(basename $interface)
                echo "name:$name"
            done
            if [ ! -e "/sys/class/net/$name" ]; then
                echo "$name not found!!!"
                Switching_mode "$device_dir"
                if [ -e $DIRECTORY/$Serial_port ]; then
                    echo -e "AT+QCFG=\"usbnet\",0" >$DIRECTORY/$Serial_port
                    sleep 1
                    /usr/bin/quectel-CM >>/tmp/4G.log 2>&1 &
                else
                    echo "The Serial_port not found!!!"
                fi
            else
                echo "This is EC20 Connection test"
                ping -c 2 -W 3 -I $name 8.8.8.8
                if [ ! "$?" == "0" ]; then
                    echo "EC20 Connect faile!!!"
                    Switching_mode "$device_dir"
                    if [ -e $DIRECTORY/$Serial_port ]; then
                        #echo -e "AT+QCFG=\"usbnet\",0" > $DIRECTORY/$Serial_port
                        sleep 1
                        /usr/bin/quectel-CM >>/tmp/4G.log 2>&1 &
                    else
                        echo "The Serial_port not found!!!"
                    fi
                else
                    echo "EC20 Connect success!"
                    exit 1
                fi
            fi
        fi

        # RG200U
        if [ "$product_id" = "0900" ]; then
            RG200U_config "$device_dir"
        fi
    fi
done
