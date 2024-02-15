# Labgrid tools
*Labgrid tools placed here are used for labgrid automation.*  
*From prepare script to integration with other tools like netbox.*

**Contacts: Mateusz Redzynia**
### Labgrid prepare script
#### Script can be run in two ways:

Script can be run for user or root, differences are explained below.
| Modes | User | Root |
|----|-----|-------|
| install | Install labgrid using pip | Clone github repository and then install using pip | False |
| configure | Change *ssh.py* file located in user labgrid directory | Change *ssh.py* file located in global python libraries | False|
> **_NOTE:_** When using admin or docker images supplied by devops team there is no need to install labgrid.

Below table explains all arguments script can use.
| Arguments | Description | Mandatory | Values |
|:-----------|:------|:-------|:-------|
| -l / labgrid coordinator | Web socet address of labgrid coordinator for which env has to be prepared | **True** | websocket addres of coordinator ws://address:port:/ws |
| -i / install | Perform installation of labgrid | False | True / False |
| -c / configure | Configure labgrid library files | False| True / False |
| -p / proxy | If labgrid places are located in different subnets use proxy | False | Address of proxy-jump host|
| -s / scope | Scope on which test will be performed, by default smoke scope will be tested - only 5 first places | False | full / smoke |
| -g / generate | Generate report of available places in json format | False | True / False |
| -r / report | Specify filename of generated report | **True if -g is True!** | *filename*.json |

> **_NOTE:_** to get labgrid-coordinator address refer to [labgrid documentation of zephyr team.](https://intel-innersource.github.io/os.rtos.zephyr.devops.documentation/user_guides/labgrid_user_guide.html)

##### Testing your configuration
Below command will connect to provided labgrid coordinator and test connection to first 5 places
> ./prepare-labgrid-env.sh -l *labgrid-coordinator* 

When willing to test full scope of platforms use *-s full*
> ./prepare-labgrid-env.sh -l *labgrid-coordinator* -s *full*

##### Installation and configuration
When installing labgrid with script use *-i true* and *-c true*
> ./prepare-labgrid-env.sh -l *labgrid-coordinator* -i *true* -c *true*

> **_NOTE:_** When installing fresh labgrid configuration is mandatory, if omited ssh connection will not be possible

##### Configuration
When labgrid library has to be configured use *-c true*
> ./prepare-labgrid-env.sh -l *labgrid-coordinator* -c *true*

##### Generating reports
When generating report use *-g true* and *-r filename.json*.

> ./prepare-labgrid-env.sh -l *labgrid-coordinator* -g *true* -r *report-name.json*

Script will generate the dict in json format.
> {"places": [{"name": "place1", "ssh": true, "power": false}, ... {"name": "placex", "ssh": false, "power": false}]}

> **_NOTE:_** Generating reports is used for integration with netbox rest api


### Labgrid patch netbox

#### Description
Script is used to communicate with netbox host to patch already added devices.
Devices have to be defined in netbox with **labgrid_controlled** and **labgrid_place** fields.

Below table explains all arguments script can use.
| Arguments | Description | Mandatory | Values |
|:-----------|:------|:-------|:-------|
|--patch-labgrid-status| Mostly used with daily smoke tests. Script will update places information in netbox if place exists there.| **No** | True / False |
|--patch-labgrid-reservations| Script will update information about platforms' reservations, by whom and when platform were reserved. | **No** | True / False |
|--patch-data-file| JSON file with places dict to be updated | **No** | filename.json |
|--token | Auth token used to connect to netbox rest api | **Yes** | netbox-token |
|--netbox-host| Address of netbox host to which connection will be performed. | **Yes** | netbox host address|

> **_NOTE:_** At least one of --patch-labgrid have to be true.

If *--patch-labgrid-status* is true *--patch-data-file* has to be **provided**

#### Prerequisites
- python3
- pandas
- requests
- json
- labgrid
- labgrid-client

#### Patching labgrid status
Word *patching* is used due to requests type used in script.    
*PATCH* is used and not i.e. **POST** because we want to update already existing records and not add new.   
Script will communicate with netbox and update labgrid data per each *place*.  

> python3 labgrid-patch-netbox.py --patch-labgrid-status *True* --patch-data-file *filename.json* --token *TOKEN* --netbox-host *host-address*

#### Patching reservations
In this case script will communicate with netbox first to retrieve places to be checked.  
Loop over these places to check if any of them is acquired/locked by someone.  
Update the place in netbox using this information.  

> python3 labgrid-patch-netbox.py --patch-labgrid-reservations *True* --token *TOKEN* --netbox-host *host-address*