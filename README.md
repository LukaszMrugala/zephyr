# Intel 1RTOS / Zephyr internal CI repo
*a catch-all repo for DevOps services & documentation*

**Contact: email to: FMOS_DevOps, cc: Vondrachek, Chris & Graydon, Connor**

## Block Diagram

![Zephyr CI Block Diagram](zephyrCI-block-diagram-WW36-2021.png "zephyr CI block diagram WW36 2021")

## 1RTOS DevOps Links & Docs

### [Zephyr DevOps Overview](https://intel-my.sharepoint.com/:p:/p/christopher_g_turner/EfZ2TF9ElydPjpGBEAKiUkwBiFt5LFBZPI2aGO_HZnP7Wg?e=Bxeeho) - Updated frequently... our most-popular slide-deck!

### [sdk-docker-intel](https://github.com/intel-innersource/os.rtos.zephyr.devops.infrastructure.sdk-docker-intel/blob/main-intel/README-INTEL.md) - Zephyr SDK container modified for internal use

### [ubuntu-zephyr-devops](https://github.com/intel-innersource/os.rtos.zephyr.devops.infrastructure.ubuntu-zephyr-devops) - DevOps customized Ubuntu OS for Zephyr build & test agents

### [innersource/zephyr Actions](https://github.com/intel-innersource/os.rtos.zephyr.zephyr/actions)
### [innersource/zephyr-intel Actions](https://github.com/intel-innersource/os.rtos.zephyr.zephyr-intel/actions)

### [zephyr-ci Jenkins (production)](https://zephyr-ci.jf.intel.com/) - CI runs in Github/OneSource but some DevOps automation tasks still require Jenkins
### [zephyr-devops Jenkins (staging)](https://zephyr-devops.jf.intel.com/) - DevOps testing

### [ci.git/docs](docs/) - more DevOps documentation

## hidden.tar.secret & the hidden/ directory
DevOps infrastructure secrets & private configuration data is stored in hidden.tar.secret, a git-secret encrypted tar archive with access controlled by a GPG keyring. 

### Do I need access? What's in hidden.tar.secret anyway?
Probably not. It's just credentials & code for our underlying infrastructure & network services.

### To reveal contents of hidden.tar.secret into ./hidden/ :
1. Your public GPG key must be enrolled in the git-secret keyring - email FMOS DevOps PDL for more info. 
2. Use our automation script to decrypt hidden.tar.secret & decompress to hidden/

	````trusted-gpg-user@ci.git/ $ ./reveal-hidden.sh````

3. Access protected files at hidden/
4. If any changes are made, you MUST run ````./hide-hidden.sh```` to capture changes & re-encrypt the ./hidden directory

### To hide the contents of hidden/ & stage hidden.tar.secret for commit:
1. Your public GPG key must be enrolled in the keyring in this repo. 
2. Use our automation script to tar & encrypt ./hidden/, and also stage the change for commit:

	````trusted-gpg-user@ci.git/ $ ./hide-hidden.sh````

3. Commit changes to hidden.tar.secret & push per usual
