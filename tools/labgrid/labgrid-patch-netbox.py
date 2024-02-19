import argparse
import json
import pandas as pd
import requests
import subprocess

PARSER = argparse.ArgumentParser()
PARSER.add_argument(
    "--patch-labgrid-status", action="store", dest="patch_labgrid_status", default=False
)
PARSER.add_argument(
    "--patch-labgrid-reservations",
    action="store",
    dest="patch_labgrid_reservations",
    default=False,
)
PARSER.add_argument(
    "--patch-data-file", action="store", dest="patch_data_file", default=""
)
PARSER.add_argument("--token", action="store", dest="token", default="")
PARSER.add_argument("--netbox-host", action="store", dest="netbox_host", default="")
args = PARSER.parse_args()

FALSE_LIST = ["False", "false", False]
TRUE_LIST = ["True", "true", True]


def _execute(cmd):
    try:
        process = subprocess.Popen(
            cmd,
            shell=True,
            executable="/bin/bash",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        stdout, stderr = process.communicate(timeout=50)
    except TimeoutError:
        process.kill()
    return stdout.decode(), stderr.decode()


def get_reservation_status(coordinator, place, proxy=None):
    if place is None:
        return ["", "", ""]

    cmd = [
        f"labgrid-client -x {coordinator}",
        f"{f'-P {proxy}' if proxy else ''}",
        "who",
        f"| grep {place}",
        "| awk '{ print $1 }'",
    ]

    reserved_by, _ = _execute(" ".join(cmd))

    cmd = [
        f"labgrid-client -x {coordinator}",
        f"{f'-P {proxy}'if proxy else ''}",
        "who",
        f"| grep {place}",
        "| awk '{print $4,$5}'",
    ]
    print(f"output: {reserved_by}, error: {_}")
    reservation_date, _ = _execute(" ".join(cmd))

    if len(reserved_by) > 3:
        return [True, reserved_by.replace("\n", ""), reservation_date.replace("\n", "")]

    return [False, "", ""]


def get_labgrid_report_in_json(report_file):
    with open(report_file, "r+") as report:
        _report = json.load(report)

    reports = pd.json_normalize(_report["places"])
    reports_dict = (
        reports[["name", "ssh", "power"]].set_index(["name"]).to_dict("index")
    )

    return reports_dict


def patch_reservation(id, is_reserved=None, reserved_by=None, reservation_dt=None):

    reservation_status = requests.patch(
        f"http://{args.netbox_host}/api/dcim/devices/{id}/",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Token {args.token}",
            "Accept": "application/json; indent=2",
        },
        json={"custom_fields": {"is_reserved": is_reserved}},
    )
    reservation_user = requests.patch(
        f"http://{args.netbox_host}/api/dcim/devices/{id}/",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Token {args.token}",
            "Accept": "application/json; indent=2",
        },
        json={"custom_fields": {"reserved_by": f"{reserved_by}"}},
    )
    reservation_date = requests.patch(
        f"http://{args.netbox_host}/api/dcim/devices/{id}/",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Token {args.token}",
            "Accept": "application/json; indent=2",
        },
        json={"custom_fields": {"labgrid_reservation_date_": f"{reservation_dt}"}},
    )

    print(
        f"[DEBUG]: DEVICE:{id}; STATUS:{reservation_status} {is_reserved}; USER:{reservation_user} {reserved_by}, DATE:{reservation_date} {reservation_dt}"
    )


def patch_labgrid_status(id, labgrid_ssh_status=None, labgrid_power_status=None):
    labgrid_ssh = requests.patch(
        f"http://{args.netbox_host}/api/dcim/devices/{id}/",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Token {args.token}",
            "Accept": "application/json; indent=2",
        },
        json={"custom_fields": {"labgrid_ssh": labgrid_ssh_status}},
    )
    labgrid_power = requests.patch(
        f"http://{args.netbox_host}/api/dcim/devices/{id}/",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Token {args.token}",
            "Accept": "application/json; indent=2",
        },
        json={"custom_fields": {"labgrid_power": labgrid_power_status}},
    )

    print(
        f"[DEBUG]: DEVICE:{id}; SSH:{labgrid_ssh} {labgrid_power_status}; POWER:{labgrid_power} {labgrid_power_status}"
    )


def run(patch_reservations=True, patch_status=False):
    if not args.token:
        exit("No token provided!")
    if not args.netbox_host:
        exit("No host provided!")
    if args.patch_labgrid_status:
        reports_dict = get_labgrid_report_in_json(args.patch_data_file)
    response = requests.get(
        f"http://{args.netbox_host}/api/dcim/devices/",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Token {args.token}",
            "Accept": "application/json; indent=2",
        },
    )
    _netbox_devices = response.json()
    netbox_devices = pd.json_normalize(_netbox_devices["results"])
    netbox_devices_dict = (
        netbox_devices[
            ["id", "custom_fields.labgrid_available", "custom_fields.labgrid_place"]
        ]
        .set_index(["id"])
        .to_dict("index")
    )
    for key, value in netbox_devices_dict.items():
        if value["custom_fields.labgrid_available"] in TRUE_LIST:
            device_id = key
            labgrid_place = value["custom_fields.labgrid_place"]
            if patch_reservations:
                status, user, date = get_reservation_status(
                    coordinator="ws://admin-fmos.igk.intel.com:80/lg",
                    place=labgrid_place,
                )
                patch_reservation(
                    id=device_id,
                    is_reserved=status,
                    reserved_by=user,
                    reservation_dt=date,
                )
            if patch_status:
                ssh_status = reports_dict[labgrid_place]["ssh"]
                power_status = reports_dict[labgrid_place]["power"]
                patch_labgrid_status(
                    id=device_id,
                    labgrid_ssh_status=ssh_status,
                    labgrid_power_status=power_status,
                )


if __name__ == "__main__":
    run(
        patch_reservations=args.patch_labgrid_reservations,
        patch_status=args.patch_labgrid_status,
    )
