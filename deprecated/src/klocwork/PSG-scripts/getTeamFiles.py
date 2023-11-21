import os
import sys
import commands
parentfoldername = sys.argv[1]
sourcefoldername = sys.argv[2]
kwprojectname = sys.argv[3]

parentpath = '/home/swiplab/build/'+ parentfoldername
workpath = parentpath + '/' +sourcefoldername
tablefile = parentpath + '/my_tables/file.dat'
issuefile = parentpath + '/my_tables/problem.pbf'
resultfile = parentpath + '/result.txt'
outputstring = ''


scannedownerfiles = []
authors = ['Ley Foon Tan', 'Richard Gong', 'Tien Hock Loh', 'Boon Khai Ng', 'Joyce Ooi', 'Chang Rebecca Swee Fun', 'Dinh Nguyen', 'Dalon Westergreen', 'Radu Bacrau', 'Tien Fong Chee', 'Siew Chin Lim', 'Yau Wai Gan', 'Abdul Halim, Muhammad Hadi Asyrafi', 'khai shen, khaw', 'Matthew Gerlach']
ownerfilelist= []
os.chdir(workpath)
for each in authors:
	cmd = 'git log --name-only --author="'+ each +'" --pretty=tformat:'
	sts, outinfo = commands.getstatusoutput(cmd)
	if not outinfo == '':
		returnlist = outinfo.split('\n')
		for eachfile in returnlist:
			if eachfile not in 'CODEOWNERS' and (eachfile.endswith('.c') or eachfile.endswith('.h') or eachfile.endswith('.cpp')):
				ownerfilelist.append([each, eachfile])
#print(ownerfilelist)

file = open(tablefile, 'r')
filelist = []
try:
    while True:
        text_line = file.readline()
        if text_line and not text_line =='\n':
            filelist.append(text_line.replace('\n',''))
        else:
            break
finally:
    file.close()
#print(filelist)

for each in ownerfilelist:
	for eachfile in filelist:
		if each[1] in eachfile:
			scannedownerfiles.append(each)
#print(scannedownerfiles)

file = open(issuefile , 'rb')
issuefilelist = []
try:
    while True:
        text_line = file.readline()
        if text_line and not text_line =='\n':
            issuefilelist.append(text_line.replace('\n',''))
        else:
            break
finally:
    file.close()

ownerissuefilelist = []
for each in ownerfilelist:
	for eachissue in issuefilelist:
		if each[1] in eachissue:
			ownerissuefilelist.append(each)


if len(ownerissuefilelist) == 0:
	msg = 'No updated files(.c/.h/.cpp) by the team(' + '/'.join(authors) + ') have KW issues.'
else:
	msg = str(len(ownerissuefilelist)) + ' files updated by the team(' + '/'.join(authors) + ') have KW issues. Please go to https://klocwork-jf25.devtools.intel.com:8195/review/insight-review.html#reportviewer_goto:project='+kwprojectname+',view_id=1 to check details.'
msg = msg + '\n====================================================== \n'
outputstring  = outputstring   +'\n'+ msg

msg = str(len(ownerfilelist)) + ' files(.c/.h/.cpp) updated by the team(' + '/'.join(authors) + ') while '+ str(len(scannedownerfiles)) + ' scanned.'
outputstring  =  outputstring   +'\n'+ msg
outputstring  =  outputstring   +'\n'+ 'Files(.c/.h/.cpp) updated:'
for each in ownerfilelist:
	msg = '* ' + each[0]+':'+ each[1]
	outputstring  = outputstring   +'\n'+ msg
outputstring  =  outputstring   +'\n'+ 'Files(.c/.h/.cpp) scanned:'
for each in scannedownerfiles:
	msg = '* ' + each[0]+':'+ each[1]
	outputstring  = outputstring   +'\n'+ msg
print(outputstring)
f = open (resultfile,'w')
f.write(outputstring)
f.close()
