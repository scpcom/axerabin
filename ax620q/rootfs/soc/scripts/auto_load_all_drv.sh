#!/bin/sh

if [ $# -eq 0 ]; then
    mode="-i"
else
    mode=$1
fi

if [ -f /boot/configs ]; then
    . /boot/configs
fi

OS_MEM_MIN_SZIE=0

function get_board_id()
{
    echo 0
}

function get_emmc_size()
{
    echo 256
}

function get_os_mem_size()
{
    $(cat /proc/cmdline | grep -o "mem=[0-9]*M" | sed 's/mem=\([0-9]*\)M/\1/')
}

function get_cmm_size()
{
    board_id=$(get_board_id)
    emmc_size=$(get_emmc_size)
    if [ -n "${maix_memory_cmm}" ] && [ ${maix_memory_cmm} -gt 0 ] && [ $((emmc_size - maix_memory_cmm)) -ge ${OS_MEM_MIN_SZIE} ]; then
        echo ${maix_memory_cmm}
    else
        os_mem_size=$(get_os_mem_size)
        echo $((emmc_size - os_mem_size))
    fi
}

function get_cmm_param()
{
    emmc_size=$(get_emmc_size)
    cmm_size=$(get_cmm_size)
    os_mem_size=$OS_MEM_MIN_SIZE
    if [ $((emmc_size - cmm_size)) -ge $OS_MEM_MIN_SZIE ]; then
        os_mem_size=$((emmc_size - cmm_size))
    else
        os_mem_size=$((emmc_size / 2))
        cmm_size=$((emmc_size / 2))
    fi
    offset=$((os_mem_size * 1024 * 1024 + 0x40000000))
    printf "cmmpool=anonymous,0,%#x,%dM" "$offset" "$cmm_size"
}

function load_drv()
{
    echo "run auto_load_all_drv.sh start "
    insmod /soc/ko/ax_sys.ko
    cmm_param=$(get_cmm_param)
    echo "insmod ax_cmm, param: $cmm_param"
    insmod /soc/ko/ax_cmm.ko $cmm_param
    insmod /soc/ko/ax_pool.ko
    insmod /soc/ko/ax_base.ko
    insmod /soc/ko/ax_npu.ko
    insmod /soc/ko/ax_ivps.ko
    insmod /soc/ko/ax_vpp.ko
    insmod /soc/ko/ax_gdc.ko
    insmod /soc/ko/ax_tdp.ko
    insmod /soc/ko/ax_vo.ko
    insmod /soc/ko/ax_venc.ko
    insmod /soc/ko/ax_jenc.ko
    insmod /soc/ko/ax_mipi_rx.ko
    insmod /soc/ko/ax_proton.ko
    insmod /soc/ko/ax_audio.ko

    echo "run auto_load_all_drv.sh end "
}

function remove_drv()
{
    rmmod ax_audio
    rmmod ax_proton
    rmmod ax_mipi_rx
    rmmod ax_jenc
    rmmod ax_venc
    rmmod ax_vo
    rmmod ax_tdp
    rmmod ax_gdc
    rmmod ax_vpp
    rmmod ax_ivps
    rmmod ax_npu
    rmmod ax_base
    rmmod ax_pool
    rmmod ax_cmm
    rmmod ax_sys
}

function auto_drv()
{
    if [ "$mode" == "-i" ]; then
        load_drv
    elif [ "$mode" == "-r" ]; then
        remove_drv
    else
        echo "[error] Invalid param, please use the following parameters:"
        echo "-i:  insmod"
        echo "-r:  rmmod"
    fi
}

auto_drv

exit 0
