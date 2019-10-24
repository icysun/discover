#!/bin/bash
#
# by Lee Baird
# Contact me via chat or email with any feedback or suggestions that you may have:
# leebaird@gmail.com
#
# Special thanks to the following people:
#
# Jay Townsend - conversion from Backtrack to Kali, manages pull requests & issues
# Jason Ashton (@ninewires)- Penetration Testers Framework (PTF) compatibility, Registered Domains, bug crusher, and bash ninja
#
# Ben Wood (@DilithiumCore) - regex master
# Dave Klug - planning, testing and bug reports
# Jason Arnold (@jasonarnold) - planning original concept, author of ssl-check and co-author of crack-wifi
# John Kim - python guru, bug smasher, and parsers
# Eric Milam (@Brav0Hax) - total re-write using functions
# Hector Portillo - report framework v3
# Ian Norden (@iancnorden) - report framework v2
# Martin Bos (@cantcomputer) - IDS evasion techniques
# Matt Banick - original development
# Numerous people on freenode IRC - #bash and #sed (e36freak)
# Rob Dixon (@304geek) - report framework concept
# Robert Clowser (@dyslexicjedi)- all things
# Saviour Emmanuel - Nmap parser
# Securicon, LLC. - for sponsoring development of parsers
# Steve Copland - report framework v1
# Arthur Kay (@arthurakay) - python scripts

##############################################################################################################

# Catch process termination
trap f_terminate SIGHUP SIGINT SIGTERM

##############################################################################################################

# Check for instances of Discover >1
updatedb
locate discover.sh > tmpinstance
instqty=$(wc -l tmpinstance | cut -d ' ' -f1)

if [ $instqty -gt 1 ]; then
     echo
     echo -e "$medium ${NC}"
     echo
     echo -e "Found ${YELLOW}$instqty${NC} instances of Discover on your system."
     echo 'Refer to the following paths:'
     cat tmpinstance | sed 's/^/\t/'
     echo
     echo 'Remove or rename all but the install path and try again.'
     echo -e "If renaming, ${YELLOW}'discover.sh'${NC} can't be in name. Try ${YELLOW}'discover.bu'${NC} etc."
     echo
     echo -e "${YELLOW}$medium ${NC}"
     echo
     rm tmpinstance
     exit
else
     rm tmpinstance
fi

##############################################################################################################

# Global variables
CWD=$(pwd)
discover=$(updatedb; locate discover.sh | sed 's:/[^/]*$::')
home=$HOME
interface=$(ip addr | grep 'global' | awk '{print $8}')
ip=$(ip addr | grep 'global' | cut -d '/' -f1 | awk '{print $2}')
port=443
rundate=$(date +%B' '%d,' '%Y)
sip='sort -n -u -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4'
web="firefox -new-tab"

long='==============================================================================================================================='
medium='=================================================================='
short='========================================'

BLUE='\033[1;34m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

##############################################################################################################

export CWD
export discover
export home
export interface
export ip
export port
export rundate
export sip
export web

export long
export medium
export short

export BLUE
export RED
export YELLOW
export NC

##############################################################################################################

f_banner(){
echo
echo -e "${YELLOW}
 _____  ___  _____  _____  _____  _    _  _____  _____
|     \  |  |____  |      |     |  \  /  |____  |____/
|_____/ _|_ _____| |_____ |_____|   \/   |_____ |    \_

By Lee Baird${NC}"
echo
echo
}

export -f f_banner

##############################################################################################################

f_error(){
echo
echo -e "${RED}$medium${NC}"
echo
echo -e "${RED}                *** Invalid choice or entry. ***${NC}"
echo
echo -e "${RED}$medium${NC}"
echo
echo
exit
}

export -f f_error

##############################################################################################################

f_location(){
echo
echo -n "Enter the location of your file: "
read -e location

# Check for no answer
if [[ -z $location ]]; then
     f_error
fi

# Check for wrong answer
if [ ! -f $location ]; then
     f_error
fi
}

export -f f_location

##############################################################################################################

f_runlocally(){
if [[ -z $DISPLAY ]]; then
     echo
     echo -e "${RED}$medium${NC}"
     echo
     echo -e "${RED}             *** This option must be ran locally. ***${NC}"
     echo
     echo -e "${RED}$medium${NC}"
     echo
     echo
     exit
fi
}

export -f f_runlocally

##############################################################################################################

f_terminate(){
save_dir=$home/data/cancelled-$(date +%H:%M:%S)
echo
echo "Terminating..."
echo
echo -e "${YELLOW}All data will be saved in $save_dir.${NC}"

mkdir $save_dir

# Nmap and Metasploit scans
mv $name/ $save_dir 2>/dev/null

# Passive files
cd $discover/
mv curl debug* email* hosts name* network* records registered* squatting sub* tmp ultratools usernames-recon whois* z* doc pdf ppt txt xls $save_dir/passive/ 2>/dev/null
cd /tmp/; mv emails names* networks subdomains usernames $save_dir/passive/recon-ng/ 2>/dev/null

# Active files
cd $discover/
mv active.rc emails hosts record* sub* waf whatweb z* $save_dir/active/ 2>/dev/null
cd /tmp/; mv subdomains $save_dir/active/recon-ng/ 2>/dev/null
cd $discover/

echo
echo "Saving complete."
echo
echo
exit
}

##############################################################################################################

f_domain(){
clear
f_banner

echo -e "${BLUE}RECON${NC}"
echo
echo "1.  Passive"
echo "2.  Active"
echo "3.  Import names into an existing recon-ng workspace"
echo "4.  Previous menu"
echo
echo -n "Choice: "
read choice

case $choice in
     1) $discover/passive.sh && exit;;

     2) $discover/active.sh && exit;;

     3)
     clear
     f_banner

     echo -e "${BLUE}Import names into an existing recon-ng workspace.${NC}"
     echo
     echo "Example: last, first"
     f_location
     echo "last_name#first_name" > /tmp/names.csv
     sed 's/, /#/' $location  >> /tmp/names.csv

     echo -n "Use Workspace: "
     read -e workspace

     # Check for no answer
     if [[ -z $workspace ]]; then
          f_error
     fi

     # Check for wrong answer
     if [ ! -d /root/.recon-ng/workspaces/$workspace ]; then
          f_error
     fi

     if [ ! -d $home/data/$workspace ]; then
          mkdir -p $home/data/$workspace
     fi

     echo "workspaces select $workspace" > tmp.rc
     cat $discover/resource/recon-ng-import-names.rc >> tmp.rc
     cat $discover/resource/recon-ng-cleanup.rc >> tmp.rc
     sed -i "s/yyy/$workspace/g" tmp.rc

     recon-ng -r $discover/tmp.rc
     rm tmp.rc

     grep '@' emails | cut -d ' ' -f4 | egrep -v '(email|SELECT|username)' | sort -u > $home/data/$workspace/emails.txt
     sed '1,4d' /tmp/names | head -n -5 > $home/data/$workspace/names.txt
     sed '1,4d' /tmp/usernames | head -n -5 > $home/data/$workspace/usernames.txt
     cd /tmp/; rm emails names* usernames 2>/dev/null

     echo
     echo $medium
     echo
     echo -e "The new files are located at ${YELLOW}$home/data/$workspace/${NC}\n"
     echo
     echo
     exit
     ;;

     4) f_main;;

     *) f_error;;
esac
}

##############################################################################################################

f_person(){
f_runlocally
clear
f_banner

echo -e "${BLUE}RECON${NC}"
echo
echo -n "First name: "
read firstName

# Check for no answer
if [[ -z $firstName ]]; then
     f_error
fi

echo -n "Last name:  "
read lastName

# Check for no answer
if [[ -z $lastName ]]; then
     f_error
fi

$web &
sleep 2
$web http://www.411.com/name/$firstName-$lastName/ &
sleep 2
uripath="http://www.advancedbackgroundchecks.com/search/results.aspx?type=&fn=${firstName}&mi=&ln=${lastName}&age=&city=&state="
$web $uripath &
sleep 2
$web https://www.linkedin.com/pub/dir/?first=$firstName\&last=$lastName\&search=Search &
sleep 2
$web http://www.peekyou.com/$firstName%5f$lastName &
sleep 2
$web http://phonenumbers.addresses.com/people/$firstName+$lastName &
sleep 2
$web https://pipl.com/search/?q=$firstName+$lastName\&l=\&sloc=\&in=5 &
sleep 2
$web http://www.spokeo.com/$firstName-$lastName &
sleep 2
$web https://twitter.com/search?q=%22$firstName%20$lastName%22&src=typd &
sleep 2
$web https://www.youtube.com/results?search_query=$firstName+$lastName &
sleep 2
$web http://www.zabasearch.com/query1_zaba.php?sname=$firstName%20$lastName&state=ALL&ref=$ref&se=$se&doby=&city=&name_style=1&tm=&tmr= &

f_main
}

##############################################################################################################

f_salesforce(){
clear
f_banner

echo -e "${BLUE}Create a free account at salesforce (https://connect.data.com/login).${NC}"
echo -e "${BLUE}Perform a search on your target > select the company name > see all.${NC}"
echo -e "${BLUE}Copy the results into a new file.${NC}"
echo -e "${BLUE}[*] Note: each record should be on a single line.${NC}"

f_location

echo

# Remove blank lines, strings, and leading white space. Set tab as the delimiter
cat $location | sed '/^$/d; s/Direct Dial Available//g; s/[] 	//g; s/^[ \t]*//; s/ \+ /\t/g' > tmp

# Place names into a file and sort by uniq
cut -d $'\t' -f1 tmp | sort -u > tmp2

# grep name, sort by data field, then uniq by the name field - selecting the most recent entry
# select and and title from result and colon delimit into file
while read line; do
    grep "$line" tmp | sort -t ',' -k7M | sort -uk1,1r | awk -F$'\t' '{print $1":"$3}' | sed 's/ :/:/g' >> tmp3
done < tmp2

column -s ':' -t tmp3 > tmp4

# Clean-up
cat tmp4 | sed 's/ -- /, /g; s/ - /, /g; s/,,/,/g; s/, ,/, /g; s/\//, /g; s/[^ ]\+/\L\u&/g; s/-.*$//g; s/1.*$//g; s/1/I/g; s/2/II/g; s/3/III/g; s/4/IV/g; 
s/5/V/g; s/2cfinancedistributionoperations//g; s/-administration/, Administration/g; s/-air/, Air/g; s/, ,  and$//g; s/ And / and /g; s/ at.*$//g; 
s/ asic / ASIC /g; s/ Asm/ ASM/g; ; s/ api / API /g; s/AssistantChiefPatrolAgent/Assistant Chief Patrol Agent/g; s/-associate/-associate/g; s/ at .*//g; 
s/ At / at /g; s/ atm / ATM /g; s/ bd / BD /g; s/-big/, Big/g; s/BIIb/B2B/g; s/-board/, Board/g; s/-boiler/, Boiler/g; s/ bsc / BSC /g; s/-call/, Call/g; 
s/-capacity/, Capacity/g; s/-cash/, Cash/g; s/ cbt / CBT /g; s/ Cc/ CC/g; s/-chief/, Chief/g; s/ cip / CIP /g; s/ cissp / CISSP /g; s/-civil/, Civil/g; 
s/ cj / CJ /g; s/Clients//g; s/ cmms / CMMS /g; s/ cms / CMS /g; s/-commercial/, Commercial/g; 
s/CommitteemanagementOfficer/Committee Management Officer/g; s/-communications/, Communications/g; s/-community/, Community/g;
s/-compliance/, Compliance/g; s/-consumer/, Consumer/g; s/contact sold, to//g; s/-corporate/, Corporate/g; s/ cpa/ CPA/g; s/-creative/, Creative/g; 
s/ Crm / CRM /g; s/ Csa/ CSA/g; s/ Csc/ CSC/g; s/ctr /Center/g; s/-customer/, Customer/g; s/Datapower/DataPower/g; s/-data/, Data/g; s/ db2 / DB2 /g; 
s/ dbii / DB2 /g; s/ Dc/ DC/g; s/DDesigner/Designer/g; s/DesignatedFederalOfficial/Designated Federal Official/g; s/-design/, Design/g; s/dhs/DHS/g; 
s/-digital/, Digital/g; s/-distribution/, Distribution/g; s/ Disa / DISA /g; s/ dns / DNS /g; s/-dominion/-dominion/g; s/-drilling/, Drilling/g; 
s/ dvp / DVP /g; s/ ebs / EBS /g; s/ Edi / EDI /g; s/editorr/Editor/g; s/ edrm / EDRM /g; s/ eeo / EEO /g; s/ efi / EFI /g; s/-electric/, Electric/g; 
s/EleCenterEngineer/Electric Engineer/g; s/ emc / EMC /g; s/ emea/ EMEA/g; s/-employee/, Employee/g; s/ ems / EMS /g; s/-energy/, Energy/g; 
s/engineer5/Engineer V/g; s/-engineering/, Engineering/g; s/-engineer/, Engineer/g; s/-environmental/, Environmental/g; s/-executive/, Executive/g; 
s/faa / FAA /g; s/-facilities/, Facilities/g; s/ Fdr / FDR /g; s/ ferc / FERC /g; s/ fha / FHA /g; s/-finance/, Finance/g; s/-financial/, Financial/g; 
s/-fleet/, Fleet/g; s/ For / for /g; s/ fsa / FSA /g; s/ fso / FSO /g; s/ fx / FX /g; s/ gaap / GAAP /g; s/-gas/, Gas/g; s/-general/, General/g; 
s/-generation/, Generation/g; s/grp/Group/g; s/ gsa / GSA /g; s/ gsis / GSIS /g; s/ gsm / GSM /g; s/Hbss/HBSS/g; s/ hd / HD /g; s/ hiv / HIV /g; 
s/ hmrc / HMRC /g; s/ hp / HP /g; s/ hq / HQ /g; s/ hris / HRIS /g; s/-human/, Human/g; s/ hvac / HVAC /g; s/ ia / IA /g; s/ id / ID /g; s/ iii/ III/g; 
s/ Ii/ II/g; s/ Iis / IIS /g; s/ In / in /g; s/-industrial/, Industrial/g; s/information technology/IT/g; s/-information/, Information/g; 
s/-infrastructure/, Infrastructure/g; s/-instrumentation/, Instrumentation/g; s/-internal/, Internal/g; s/ ip / IP /g; s/ ir / IR /g; s/ Issm/ ISSM/; 
s/itenterpriseprojectmanager/IT Enterprise Project Manager/g; s/-IT/, IT/g; s/ iv / IV /g; s/ Iv,/ IV,/g; s/Jboss/JBoss/g; s/ jc / JC /g; s/ jd / JD /g; 
s/ jt / JT /g; s/konsult, konsultchef, projektledare/Consultant/g; s/laboratorynetwork/Laboratory, Network/g; s/-labor/, Labor/g; 
s/lan administrator/LAN Administrator/g; s/lan admin/LAN Admin/g; s/-land/, Land/g; s/-licensing/, Licensing/g; s/LawIII60/Law360/g; s/ llc / LLC. /g; 
s/-logistics/, Logistics/g; s/ Lp/ LP/g; s/lvl/Level/g; s/-mail/, Mail/g; s/-manager/, Manager/g; s/-marketing/, Marketing/g; s/-materials/, Materials/g; 
s/ mba / MBA /g; s/Mca/McA/g; s/Mcb/McB/g; s/Mcc/McC/g; s/Mcd/McD/g; s/Mce/McE/g; s/Mcf/McF/g; s/Mcg/McG/g; s/Mch/McH/g; s/Mci/McI/g; s/Mcj/McJ/g; 
s/Mck/McK/g; s/Mcl/McL/g; s/Mcm/McM/g; s/Mcn/McN/g; s/Mcp/McP/g; s/Mcq/McQ/g; s/Mcs/McS/g; s/Mcv/McV/g; s/mcse/MCSE/g; s/-mechanical/, Mechanical/g; 
s/-metals/, Metals/g; s/-metro/, Metro/g; s/, mp//g; s/ nerc / NERC /g; s/mcp/McP/g; s/mcq/McQ/g; s/mcs/McS/g; s/-media/, Media/g; 
s/-mergers/,Mergers/g; s/-millstone/, Millstone/g; s/-motor/, Motor/g; s/ mssp / MSSP /g; s/-networking/, Networking/g; s/-network/, Network/g; 
s/-new/, New/g; s/-north/, North/g; s/not in it//g; s/ nso / NSO /g; s/-nuclear/, Nuclear/g; s/ Nz / NZ /g; s/ oem / OEM /g; s/-office/, Office/g; 
s/ Of / of /g; s/-operations/, Operations/g; s/-oracle/, Oracle/g; s/-other/, Other/g; s/ pca / PCA /g; s/ pcs / PCS /g; s/ pc / PC /g; s/ pdm / PDM /g; 
s/ phd / PhD /g; s/ pj / PJ /g; s/-plant/, Plant/g; s/plt/Plant/g; s/pmo/PMO/g; s/Pmp/PMP/g; s/ pm / PM /g; s/ Pm / PM /g; s/-power/, Power/g; 
s/-property/, Property/g; s/-public/, Public/g; s/ Psa/ PSA/g; s/pyble/Payble/g; s/ os / OS /g; s/r&d/R&D/g; s/ r and d /R&D/g; s/-records/, Records/g; 
s/-regulated/, Regulated/g; s/-regulatory/, Regulatory/g; s/-related/, Related/g; s/-remittance/, Remittance/g; s/-renewals/, Renewals/g; 
s/-revenue/, Revenue/g; s/ rfid / RFID /g; s/ rfp / RFP /g; s/ rf / RF /g; s/ Roip / RoIP /g; s/Rtls/RTLS/g; s/ Rtm/ RTM/g; s/saas/SaaS/g; 
s/-safety/, Safety/g; s/san manager/SAN Manager/g; s/scada/SCADA/g; s/sdlc/SDLC/g; s/setac-/SETAC,/g; s/sftwr/Software/g; s/-short/, Short/g; 
s/ smb / SMB /g; s/sms/SMS/g; s/smtp/SMTP/g; s/snr/Senior/g; s/.specialist./ Specialist /g; s/ Soc / SOC /g; s/sql/SQL/g; s/spvr/Supervisor/g; 
s/srbranch/Senior Branch/g; s/srsales/Senior Sales/g; s/ ssl / SSL /g; s/-staff/, Staff/g; s/stf/Staff/g; s/-station/, Station/g; 
s/-strategic/, Strategic/g; s/-student/, Student/g; s/-substation/, Substation/g; s/-supplier/, Supplier/g; s/-supply/, Supply/g; 
s/-surveillance/, Surveillance/g; s/swepco/SWEPCO/g; s/-system/, System/g; s/-tax/, Tax/g; s/-technical/, Technical/g; 
s/-telecommunications/, Telecommunications/g; s/ The / the /g; s/-three/, Three/g; s/-tickets/, Tickets/g; s/TierIII/Tier III/g; s/-trading/, Trading/g; 
s/-transmission/, Transmission/g; s/ttechnical/Technical/g; s/-turbine/, Turbine/g; s/ to .*$//g; s/ ui / UI /g; s/ uk / UK /g; 
s/unsupervisor/Supervisor/g; s/uscg/USCG/g; s/ usa / USA /g; s/ us / US /g; s/ Us / US /g; s/ u.s / US /g; s/usmc/USMC/g; s/-utility/, Utility/g; 
s/ ux / UX /g; s/vicepresident/Vice President/g; s/ Va / VA /g; s/ vii / VII /g; s/ vi / VI /g; s/ vms / VMS /g; s/ voip / VoIP /g; s/ vpn / VPN /g; 
s/Weblogic/WebLogic/g; s/Websphere/WebSphere/g; s/ With / with /g' > tmp5

# Remove lines that contain 2 words and clean up.
awk 'NF != 2' tmp5 | sed "s/d'a/D'A/g; s/d'c/D'C/g; s/d'e/D'E/g; s/d'h/D'H/g; s/d's/D'S/g; s/l'a/L'A/g; s/o'b/O'B/g; s/o'c/O'C/g; s/o'd/O'D/g; 
s/o'f/O'F/g; s/o'g/O'G/g; s/o'h/O'H/g; s/o'k/O'K/g; s/o'l/O'L/g; s/o'm/O'M/g; s/o'N/O'N/g; s/Obrien/O'Brien/g; s/Oconnor/O'Connor/g; 
s/Odonnell/O'Donnell/g; s/Ohara/O'Hara/g; s/o'p/O'P/g; s/o'r/O'R/g; s/o's/O'S/g; s/Otoole/O'Toole/g; s/o't/O'T/i" > tmp6

# Replace parenthesis and the contents inside with spaces - thanks Mike G
cat tmp6 | perl -pe 's/(\(.*\))/q[ ] x length $1/ge' > tmp7

# Remove trailing white space, railing commas, and delete lines with a single word
sed 's/[ \t]*$//; s/,$//; /[[:blank:]]/!d' tmp7 | sort -u > $home/data/names.txt
rm tmp*

echo
echo $medium
echo
echo -e "The new report is located at ${YELLOW}$home/data/names.txt${NC}\n"
echo
echo
exit
}

##############################################################################################################

f_generateTargetList(){
clear
f_banner

echo -e "${BLUE}SCANNING${NC}"
echo
echo "1.  Local area network"
echo "2.  NetBIOS"
echo "3.  netdiscover"
echo "4.  Ping sweep"
echo "5.  Previous menu"
echo
echo -n "Choice: "
read choice

case $choice in
     1) echo
     echo -n "Interface to scan: "
     read interface

     # Check for no answer
     if [[ -z $interface ]]; then
          f_error
     fi

     arp-scan -l -I $interface | egrep -v '(arp-scan|Interface|packets|Polycom|Unknown)' | awk '{print $1}' | $sip | sed '/^$/d' > $home/data/hosts-arp.txt

     echo $medium
     echo
     echo "***Scan complete.***"
     echo
     echo
     echo -e "The new report is located at ${YELLOW}$home/data/hosts-arp.txt${NC}\n"
     echo
     echo
     exit;;
     2) f_netbios;;
     3) f_netdiscover;;
     4) f_pingsweep;;
     5) f_main;;
     *) f_error;;
esac
}

##############################################################################################################

f_netbios(){
clear
f_banner

echo -e "${BLUE}Type of input:${NC}"
echo
echo "1.  List containing IPs."
echo "2.  CIDR"
echo
echo -n "Choice: "
read choice

case $choice in
     1)
     f_location

     echo
     echo $medium
     echo
     nbtscan -f $location
     echo
     echo
     exit;;

     2)
     echo
     echo -n "Enter your CIDR: "
     read cidr

     # Check for no answer
     if [[ -z $cidr ]]; then
          f_error
     fi

     echo
     echo $medium
     echo
     nbtscan -r $cidr
     echo
     echo
     exit;;

     *) f_error;;
esac
}

##############################################################################################################

f_netdiscover(){

range=$(ip addr | grep 'global' | cut -d '/' -f1 | awk '{print $2}' | cut -d '.' -f1-3)'.1'

netdiscover -r $range -f -P | grep ':' | awk '{print $1}' > $home/data/netdiscover.txt

echo
echo $medium
echo
echo "***Scan complete.***"
echo
echo
echo -e "The new report is located at ${YELLOW}$home/data/netdiscover.txt${NC}\n"
echo
echo
exit
}

##############################################################################################################

f_pingsweep(){
clear
f_banner
f_typeofscan

echo -e "${BLUE}Type of input:${NC}"
echo
echo "1.  List containing IPs, ranges and/or CIDRs."
echo "2.  Manual"
echo
echo -n "Choice: "
read choice

case $choice in
     1)
     f_location

     echo
     echo "Running an Nmap ping sweep for live hosts."
     nmap -sn -PS -PE --stats-every 10s -g $sourceport -iL $location > tmp
     ;;

     2)
     echo
     echo -n "Enter your targets: "
     read manual

     # Check for no answer
     if [[ -z $manual ]]; then
          f_error
     fi

     echo
     echo "Running an Nmap ping sweep for live hosts."
     nmap -sn -PS -PE --stats-every 10s -g $sourceport $manual > tmp
     ;;

     *) f_error;;
esac

cat tmp | grep 'report' | awk '{print $5}' > tmp2
mv tmp2 $home/data/hosts-ping.txt
rm tmp

echo
echo $medium
echo
echo "***Scan complete.***"
echo
echo
echo -e "The new report is located at ${YELLOW}$home/data/hosts-ping.txt${NC}\n"
echo
echo
exit
}

##############################################################################################################

f_scanname(){
f_typeofscan

echo -e "${YELLOW}[*] Warning spaces in the name will cause errors${NC}"
echo
echo -n "Name of scan: "
read name

# Check for no answer
if [[ -z $name ]]; then
     f_error
fi

mkdir -p $name
}

##############################################################################################################

f_typeofscan(){
echo -e "${BLUE}Type of scan: ${NC}"
echo
echo "1.  External"
echo "2.  Internal"
echo "3.  Previous menu"
echo
echo -n "Choice: "
read choice

case $choice in
     1)
     echo
     echo -e "${YELLOW}[*] Setting source port to 53 and max probe round trip to 1.5s.${NC}"
     sourceport=53
     maxrtt=1500ms
     echo
     echo $medium
     echo
     ;;

     2)
     echo
     echo -e "${YELLOW}[*] Setting source port to 88 and max probe round trip to 500ms.${NC}"
     sourceport=88
     maxrtt=500ms
     echo
     echo $medium
     echo
     ;;

     3) f_main;;
     *) f_error;;
esac
}

##############################################################################################################

f_cidr(){
clear
f_banner
f_scanname

echo
echo Usage: 192.168.0.0/16
echo
echo -n "CIDR: "
read cidr

# Check for no answer
if [[ -z $cidr ]]; then
     rm -rf $name
     f_error
fi

# Check for wrong answer

sub=$(echo $cidr | cut -d '/' -f2)
max=32

if [ "$sub" -gt "$max" ]; then
     f_error
fi

echo $cidr | grep '/' > /dev/null 2>&1

if [ $? -ne 0 ]; then
     f_error
fi

echo $cidr | grep [[:alpha:]\|[,\\]] > /dev/null 2>&1

if [ $? -eq 0 ]; then
     f_error
fi

echo $cidr > tmp-list
location=tmp-list

echo
echo -n "Do you have an exclusion list? (y/N) "
read exclude

if [ "$exclude" == "y" ]; then
     echo -n "Enter the path to the file: "
     read excludefile

     if [[ -z $excludefile ]]; then
          f_error
     fi

     if [ ! -f $excludefile ]; then
          f_error
     fi
else
     touch tmp
     excludefile=tmp
fi

START=$(date +%r\ %Z)

f_scan
f_ports
f_scripts
f_run-metasploit
f_report
}

##############################################################################################################

f_list(){
clear
f_banner
f_scanname
f_location

touch tmp
excludefile=tmp

START=$(date +%r\ %Z)

f_scan
f_ports
f_scripts
f_run-metasploit
f_report
}

##############################################################################################################

f_single(){
clear
f_banner
f_scanname

echo
echo -n "IP, range, or URL: "
read target

# Check for no answer
if [[ -z $target ]]; then
     rm -rf $name
     f_error
fi

echo $target > tmp-target
location=tmp-target

touch tmp
excludefile=tmp

START=$(date +%r\ %Z)

f_scan
f_ports
f_scripts
f_run-metasploit
f_report
}

##############################################################################################################

f_scan(){
custom='1-1040,1050,1080,1099,1158,1344,1352,1433,1521,1720,1723,1883,1911,1962,2049,2202,2375,2628,2947,3000,3031,3050,3260,3306,3310,3389,3500,3632,4369,5000,5019,5040,5060,5432,5560,5631,5632,5666,5672,5850,5900,5920,5984,5985,6000,6001,6002,6003,6004,6005,6379,6666,7210,7634,7777,8000,8009,8080,8081,8091,8140,8222,8332,8333,8400,8443,8834,9000,9084,9100,9160,9600,9999,10000,11211,12000,12345,13364,19150,27017,28784,30718,35871,37777,46824,49152,50000,50030,50060,50070,50075,50090,60010,60030'
full='1-65535'
udp='53,67,123,137,161,407,500,523,623,1434,1604,1900,2302,2362,3478,3671,4800,5353,5683,6481,17185,31337,44818,47808'

echo
echo -n "Perform full TCP port scan? (y/N) "
read scan

if [ "$scan" == "y" ]; then
     tcp=$full
else
     tcp=$custom
fi

echo
echo -n "Perform version detection? (y/N) "
read vdetection

if [ "$vdetection" == "y" ]; then
     S='sSV'
     U='sUV'
else
     S='sS'
     U='sU'
fi

echo
echo -n "Set scan delay. (0-5, enter for normal) "
read delay

# Check for no answer
if [[ -z $delay ]]; then
     delay='0'
fi

if [ $delay -lt 0 ] || [ $delay -gt 5 ]; then
     f_error
fi

f_metasploit

echo
echo $medium

nmap -iL $location --excludefile $excludefile --privileged -n -PE -PS21-23,25,53,80,110-111,135,139,143,443,445,993,995,1723,3306,3389,5900,8080 -PU53,67-69,123,135,137-139,161-162,445,500,514,520,631,1434,1900,4500,5353,49152 -$S -$U -O --osscan-guess --max-os-tries 1 -p T:$tcp,U:$udp --max-retries 3 --min-rtt-timeout 100ms --max-rtt-timeout $maxrtt --initial-rtt-timeout 500ms --defeat-rst-ratelimit --min-rate 450 --max-rate 15000 --open --stats-every 10s -g $sourceport --scan-delay $delay -oA $name/nmap

x=$(grep '(0 hosts up)' $name/nmap.nmap)

if [[ -n $x ]]; then
     rm -rf "$name" tmp
     echo
     echo $medium
     echo
     echo "***Scan complete.***"
     echo
     echo
     echo -e "${YELLOW}[*] No live hosts were found.${NC}"
     echo
     echo
     exit
fi

# Clean up
egrep -iv '(0000:|0010:|0020:|0030:|0040:|0050:|0060:|0070:|0080:|0090:|00a0:|00b0:|00c0:|00d0:|1 hop|closed|guesses|guessing|filtered|fingerprint|general purpose|initiated|latency|network distance|no exact os|no os matches|os:|os cpe|please report|rttvar|scanned in|sf|unreachable|warning)' $name/nmap.nmap | sed 's/Nmap scan report for //g; /^$/! b end; n; /^$/d; : end' > $name/nmap.txt

grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' $name/nmap.nmap | $sip > $name/hosts.txt
hosts=$(wc -l $name/hosts.txt | cut -d ' ' -f1)

grep 'open' $name/nmap.txt | grep -v 'WARNING' | awk '{print $1}' | sort -un > $name/ports.txt
grep 'tcp' $name/ports.txt | cut -d '/' -f1 > $name/ports-tcp.txt
grep 'udp' $name/ports.txt | cut -d '/' -f1 > $name/ports-udp.txt

grep 'open' $name/nmap.txt | grep -v 'really open' | awk '{for (i=4;i<=NF;i++) {printf "%s%s",sep, $i;sep=" "}; printf "\n"}' | sed 's/^ //' | sort -u | sed '/^$/d' > $name/banners.txt

for i in $(cat $name/ports-tcp.txt); do
     TCPPORT=$i
     cat $name/nmap.gnmap | grep " $i/open/tcp//http/\| $i/open/tcp//http-alt/\| $i/open/tcp//http-proxy/\| $i/open/tcp//appserv-http/" |
     sed -e 's/Host: //g' -e 's/ (.*//g' -e 's.^.http://.g' -e "s/$/:$i/g" | $sip >> tmp
     cat $name/nmap.gnmap | grep " $i/open/tcp//https/\| $i/open/tcp//https-alt/\| $i/open/tcp//ssl|giop/\| $i/open/tcp//ssl|http/\| $i/open/tcp//ssl|unknown/" |
     sed -e 's/Host: //g' -e 's/ (.*//g' -e 's.^.https://.g' -e "s/$/:$i/g" | $sip >> tmp2
done

sed 's/http:\/\///g' tmp > $name/http.txt
sed 's/https:\/\///g' tmp2 > $name/https.txt

# Remove all empty files
find $name/ -type f -empty -exec rm {} +
}

##############################################################################################################

f_ports(){
echo
echo $medium
echo
echo -e "${BLUE}Locating high value ports.${NC}"
echo "     TCP"
TCP_PORTS="13 19 21 22 23 25 37 69 70 79 80 102 110 111 119 135 139 143 389 433 443 445 465 502 512 513 514 523 524 548 554 563 587 623 631 636 771 831 873 902 993 995 998 1050 1080 1099 1158 1344 1352 1433 1521 1720 1723 1883 1911 1962 2049 2202 2375 2628 2947 3000 3031 3050 3260 3306 3310 3389 3500 3632 4369 5000 5019 5040 5060 5432 5560 5631 5632 5666 5672 5850 5900 5920 5984 5985 6000 6001 6002 6003 6004 6005 6379 6666 7210 7634 7777 8000 8009 8080 8081 8091 8140 8222 8332 8333 8400 8443 8834 9000 9084 9100 9160 9600 9999 10000 11211 12000 12345 13364 19150 27017 28784 30718 35871 37777 46824 49152 50000 50030 50060 50070 50075 50090 60010 60030"

for i in $TCP_PORTS; do
     cat $name/nmap.gnmap | grep "\<$i/open/tcp\>" | cut -d ' ' -f2 > $name/$i.txt
done

if [[ -e $name/523.txt ]]; then
     mv $name/523.txt $name/523-tcp.txt
fi

if [[ -e $name/5060.txt ]]; then
     mv $name/5060.txt $name/5060-tcp.txt
fi

echo "     UDP"
UDP_PORTS="53 67 123 137 161 407 500 523 623 1434 1604 1900 2302 2362 3478 3671 4800 5353 5683 6481 17185 31337 44818 47808"

for i in $UDP_PORTS; do
     cat $name/nmap.gnmap | grep "\<$i/open/udp\>" | cut -d ' ' -f2 > $name/$i.txt
done

if [[ -e $name/523.txt ]]; then
     mv $name/523.txt $name/523-udp.txt
fi

# Combine Apache HBase ports and sort
cat $name/60010.txt $name/60030.txt > tmp
$sip tmp > $name/apache-hbase.txt

# Combine Bitcoin ports and sort
cat $name/8332.txt $name/8333.txt > tmp
$sip tmp > $name/bitcoin.txt

# Combine DB2 ports and sort
cat $name/523-tcp.txt $name/523-udp.txt > tmp
$sip tmp > $name/db2.txt

# Combine Hadoop ports and sort
cat $name/50030.txt $name/50060.txt $name/50070.txt $name/50075.txt $name/50090.txt > tmp
$sip tmp > $name/hadoop.txt

# Combine NNTP ports and sort
cat $name/119.txt $name/433.txt $name/563.txt > tmp
$sip tmp > $name/nntp.txt

# Combine SMTP ports and sort
cat $name/25.txt $name/465.txt $name/587.txt > tmp
$sip tmp > $name/smtp.txt

# Combine X11 ports and sort
cat $name/6000.txt $name/6001.txt $name/6002.txt $name/6003.txt $name/6004.txt $name/6005.txt > tmp
$sip tmp > $name/x11.txt

# Remove all empty files
find $name/ -type f -empty -exec rm {} +
}

##############################################################################################################

f_cleanup(){
grep -v -E 'Starting Nmap|Host is up|SF|:$|Service detection performed|Nmap done|https' tmp | sed '/^Nmap scan report/{n;d}' | sed 's/Nmap scan report for/Host:/g' > tmp4
}

##############################################################################################################

f_scripts(){
echo
echo $medium
echo
echo -e "${BLUE}Running Nmap scripts.${NC}"

# If the file for the corresponding port doesn't exist, skip
if [[ -e $name/13.txt ]]; then
     echo "     Daytime"
     nmap -iL $name/13.txt -Pn -n --open -p13 --script-timeout 1m --script=daytime --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-13.txt
fi

if [[ -e $name/21.txt ]]; then
     echo "     FTP"
     nmap -iL $name/21.txt -Pn -n --open -p21 --script-timeout 1m --script=banner,ftp-anon,ftp-bounce,ftp-proftpd-backdoor,ftp-syst,ftp-vsftpd-backdoor,ssl*,tls-nextprotoneg -sV --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-21.txt
fi

if [[ -e $name/22.txt ]]; then
     echo "     SSH"
     nmap -iL $name/22.txt -Pn -n --open -p22 --script-timeout 1m --script=sshv1,ssh2-enum-algos --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-22.txt
fi

if [[ -e $name/23.txt ]]; then
     echo "     Telnet"
     nmap -iL $name/23.txt -Pn -n --open -p23 --script-timeout 1m --script=banner,cics-info,cics-enum,cics-user-enum,telnet-encryption,telnet-ntlm-info,tn3270-screen,tso-enum --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-23.txt
fi

if [[ -e $name/smtp.txt ]]; then
     echo "     SMTP"
     nmap -iL $name/smtp.txt -Pn -n --open -p25,465,587 --script-timeout 1m --script=banner,smtp-commands,smtp-ntlm-info,smtp-open-relay,smtp-strangeport,smtp-enum-users,ssl*,tls-nextprotoneg -sV --script-args smtp-enum-users.methods={EXPN,RCPT,VRFY} --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-smtp.txt
fi

if [[ -e $name/37.txt ]]; then
     echo "     Time"
     nmap -iL $name/37.txt -Pn -n --open -p37 --script-timeout 1m --script=rfc868-time --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-37.txt
fi

if [[ -e $name/53.txt ]]; then
     echo "     DNS"
     nmap -iL $name/53.txt -Pn -n -sU --open -p53 --script-timeout 1m --script=dns-blacklist,dns-cache-snoop,dns-nsec-enum,dns-nsid,dns-random-srcport,dns-random-txid,dns-recursion,dns-service-discovery,dns-update,dns-zeustracker,dns-zone-transfer --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-53.txt
fi

if [[ -e $name/67.txt ]]; then
     echo "     DHCP"
     nmap -iL $name/67.txt -Pn -n -sU --open -p67 --script-timeout 1m --script=dhcp-discover --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-67.txt
fi

if [[ -e $name/70.txt ]]; then
     echo "     Gopher"
     nmap -iL $name/70.txt -Pn -n --open -p70 --script-timeout 1m --script=gopher-ls --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-70.txt
fi

if [[ -e $name/79.txt ]]; then
     echo "     Finger"
     nmap -iL $name/79.txt -Pn -n --open -p79 --script-timeout 1m --script=finger --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-79.txt
fi

if [[ -e $name/102.txt ]]; then
     echo "     S7"
     nmap -iL $name/102.txt -Pn -n --open -p102 --script-timeout 1m --script=s7-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-102.txt
fi

if [[ -e $name/110.txt ]]; then
     echo "     POP3"
     nmap -iL $name/110.txt -Pn -n --open -p110 --script-timeout 1m --script=banner,pop3-capabilities,pop3-ntlm-info,ssl*,tls-nextprotoneg -sV --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-110.txt
fi

if [[ -e $name/111.txt ]]; then
     echo "     RPC"
     nmap -iL $name/111.txt -Pn -n --open -p111 --script-timeout 1m --script=nfs-ls,nfs-showmount,nfs-statfs,rpcinfo --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-111.txt
fi

if [[ -e $name/nntp.txt ]]; then
     echo "     NNTP"
     nmap -iL $name/nntp.txt -Pn -n --open -p119,433,563 --script-timeout 1m --script=nntp-ntlm-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-nntp.txt
fi

if [[ -e $name/123.txt ]]; then
     echo "     NTP"
     nmap -iL $name/123.txt -Pn -n -sU --open -p123 --script-timeout 1m --script=ntp-info,ntp-monlist --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-123.txt
fi

if [[ -e $name/137.txt ]]; then
     echo "     NetBIOS"
     nmap -iL $name/137.txt -Pn -n -sU --open -p137 --script-timeout 1m --script=nbstat --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     sed -i '/^MAC/{n; /.*/d}' tmp4          # Find lines that start with MAC, and delete the following line
     sed -i '/^137\/udp/{n; /.*/d}' tmp4     # Find lines that start with 137/udp, and delete the following line
     mv tmp4 $name/script-137.txt
fi

if [[ -e $name/139.txt ]]; then
     echo "     SMB Vulns"
     nmap -iL $name/139.txt -Pn -n --open -p139 --script-timeout 1m --script=smb* --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     egrep -v '(SERVICE|netbios)' tmp4 > tmp5
     sed '1N;N;/\(.*\n\)\{2\}.*VULNERABLE/P;$d;D' tmp5
     sed '/^$/d' tmp5 > tmp6
     grep -v '|' tmp6 > $name/script-smbvulns.txt
fi

if [[ -e $name/143.txt ]]; then
     echo "     IMAP"
     nmap -iL $name/143.txt -Pn -n --open -p143 --script-timeout 1m --script=imap-capabilities,imap-ntlm-info,ssl*,tls-nextprotoneg -sV --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-143.txt
fi

if [[ -e $name/161.txt ]]; then
     echo "     SNMP"
     nmap -iL $name/161.txt -Pn -n -sU --open -p161 --script-timeout 1m --script=snmp-hh3c-logins,snmp-info,snmp-interfaces,snmp-netstat,snmp-processes,snmp-sysdescr,snmp-win32-services,snmp-win32-shares,snmp-win32-software,snmp-win32-users -sV --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-161.txt
fi

if [[ -e $name/389.txt ]]; then
     echo "     LDAP"
     nmap -iL $name/389.txt -Pn -n --open -p389 --script-timeout 1m --script=ldap-rootdse,ssl*,tls-nextprotoneg -sV --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-389.txt
fi

if [[ -e $name/443.txt ]]; then
     echo "     VMware"
     nmap -iL $name/443.txt -Pn -n --open -p443 --script-timeout 1m --script=vmware-version --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-443.txt
fi

if [[ -e $name/445.txt ]]; then
     echo "     SMB"
     nmap -iL $name/445.txt -Pn -n --open -p445 --script-timeout 1m --script=msrpc-enum,smb*,stuxnet-detect --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     sed -i '/^445/{n; /.*/d}' tmp4     # Find lines that start with 445, and delete the following line
     mv tmp4 $name/script-445.txt
fi

if [[ -e $name/500.txt ]]; then
     echo "     Ike"
     nmap -iL $name/500.txt -Pn -n -sS -sU --open -p500 --script-timeout 1m --script=ike-version -sV --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-500.txt
fi

if [[ -e $name/db2.txt ]]; then
     echo "     DB2"
     nmap -iL $name/db2.txt -Pn -n -sS -sU --open -p523 --script-timeout 1m --script=db2-das-info,db2-discover --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-523.txt
fi

if [[ -e $name/524.txt ]]; then
     echo "     Novell NetWare Core Protocol"
     nmap -iL $name/524.txt -Pn -n --open -p524 --script-timeout 1m --script=ncp-enum-users,ncp-serverinfo --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-524.txt
fi

if [[ -e $name/548.txt ]]; then
     echo "     AFP"
     nmap -iL $name/548.txt -Pn -n --open -p548 --script-timeout 1m --script=afp-ls,afp-path-vuln,afp-serverinfo,afp-showmount --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-548.txt
fi

if [[ -e $name/554.txt ]]; then
     echo "     RTSP"
     nmap -iL $name/554.txt -Pn -n --open -p554 --script-timeout 1m --script=rtsp-methods --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-554.txt
fi

if [[ -e $name/623.txt ]]; then
     echo "     IPMI"
     nmap -iL $name/623.txt -Pn -n -sU --open -p623 --script-timeout 1m --script=ipmi-version,ipmi-cipher-zero --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-623.txt
fi

if [[ -e $name/631.txt ]]; then
     echo "     CUPS"
     nmap -iL $name/631.txt -Pn -n --open -p631 --script-timeout 1m --script=cups-info,cups-queue-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-631.txt
fi

if [[ -e $name/636.txt ]]; then
     echo "     LDAP/S"
     nmap -iL $name/636.txt -Pn -n --open -p636 --script-timeout 1m --script=ldap-rootdse,ssl*,tls-nextprotoneg -sV --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-636.txt
fi

if [[ -e $name/873.txt ]]; then
     echo "     rsync"
     nmap -iL $name/873.txt -Pn -n --open -p873 --script-timeout 1m --script=rsync-list-modules --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-873.txt
fi

if [[ -e $name/993.txt ]]; then
     echo "     IMAP/S"
     nmap -iL $name/993.txt -Pn -n --open -p993 --script-timeout 1m --script=banner,imap-capabilities,imap-ntlm-info,ssl*,tls-nextprotoneg -sV --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-993.txt
fi

if [[ -e $name/995.txt ]]; then
     echo "     POP3/S"
     nmap -iL $name/995.txt -Pn -n --open -p995 --script-timeout 1m --script=banner,pop3-capabilities,pop3-ntlm-info,ssl*,tls-nextprotoneg -sV --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-995.txt
fi

if [[ -e $name/1050.txt ]]; then
     echo "     COBRA"
     nmap -iL $name/1050.txt -Pn -n --open -p1050 --script-timeout 1m --script=giop-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1050.txt
fi

if [[ -e $name/1080.txt ]]; then
     echo "     SOCKS"
     nmap -iL $name/1080.txt -Pn -n --open -p1080 --script-timeout 1m --script=socks-auth-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1080.txt
fi

if [[ -e $name/1099.txt ]]; then
     echo "     RMI Registry"
     nmap -iL $name/1099.txt -Pn -n --open -p1099 --script-timeout 1m --script=rmi-dumpregistry --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1099.txt
fi

if [[ -e $name/1344.txt ]]; then
     echo "     ICAP"
     nmap -iL $name/1344.txt -Pn -n --open -p1344 --script-timeout 1m --script=icap-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1344.txt
fi

if [[ -e $name/1352.txt ]]; then
     echo "     Lotus Domino"
     nmap -iL $name/1352.txt -Pn -n --open -p1352 --script-timeout 1m --script=domino-enum-users --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1352.txt
fi

if [[ -e $name/1433.txt ]]; then
     echo "     MS-SQL"
     nmap -iL $name/1433.txt -Pn -n --open -p1433 --script-timeout 1m --script=ms-sql-dump-hashes,ms-sql-empty-password,ms-sql-info,ms-sql-ntlm-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1433.txt
fi

if [[ -e $name/1434.txt ]]; then
     echo "     MS-SQL UDP"
     nmap -iL $name/1434.txt -Pn -n -sU --open -p1434 --script-timeout 1m --script=ms-sql-dac --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1434.txt
fi

if [[ -e $name/1521.txt ]]; then
     echo "     Oracle"
     nmap -iL $name/1521.txt -Pn -n --open -p1521 --script-timeout 1m --script=oracle-tns-version,oracle-sid-brute --script oracle-enum-users --script-args oracle-enum-users.sid=ORCL,userdb=orausers.txt --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1521.txt
fi

if [[ -e $name/1604.txt ]]; then
     echo "     Citrix"
     nmap -iL $name/1604.txt -Pn -n -sU --open -p1604 --script-timeout 1m --script=citrix-enum-apps,citrix-enum-servers --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1604.txt
fi

if [[ -e $name/1723.txt ]]; then
     echo "     PPTP"
     nmap -iL $name/1723.txt -Pn -n --open -p1723 --script-timeout 1m --script=pptp-version --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1723.txt
fi

if [[ -e $name/1883.txt ]]; then
     echo "     MQTT"
     nmap -iL $name/1883.txt -Pn -n --open -p1883 --script-timeout 1m --script=mqtt-subscribe --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1883.txt
fi

if [[ -e $name/1911.txt ]]; then
     echo "     Tridium Niagara Fox"
     nmap -iL $name/1911.txt -Pn -n --open -p1911 --script-timeout 1m --script=fox-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1911.txt
fi

if [[ -e $name/1962.txt ]]; then
     echo "     PCWorx"
     nmap -iL $name/1962.txt -Pn -n --open -p1962 --script-timeout 1m --script=pcworx-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-1962.txt
fi

if [[ -e $name/2049.txt ]]; then
     echo "     NFS"
     nmap -iL $name/2049.txt -Pn -n --open -p2049 --script-timeout 1m --script=nfs-ls,nfs-showmount,nfs-statfs --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-2049.txt
fi

if [[ -e $name/2202.txt ]]; then
     echo "     ACARS"
     nmap -iL $name/2202.txt -Pn -n --open -p2202 --script-timeout 1m --script=acarsd-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-2202.txt
fi

if [[ -e $name/2302.txt ]]; then
     echo "     Freelancer"
     nmap -iL $name/2302.txt -Pn -n -sU --open -p2302 --script-timeout 1m --script=freelancer-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-2302.txt
fi

if [[ -e $name/2375.txt ]]; then
     echo "     Docker"
     nmap -iL $name/2375.txt -Pn -n --open -p2375 --script-timeout 1m --script=docker-version --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-2375.txt
fi

if [[ -e $name/2628.txt ]]; then
     echo "     DICT"
     nmap -iL $name/2628.txt -Pn -n --open -p2628 --script-timeout 1m --script=dict-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-2628.txt
fi

if [[ -e $name/2947.txt ]]; then
     echo "     GPS"
     nmap -iL $name/2947.txt -Pn -n --open -p2947 --script-timeout 1m --script=gpsd-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-2947.txt
fi

if [[ -e $name/3031.txt ]]; then
     echo "     Apple Remote Event"
     nmap -iL $name/3031.txt -Pn -n --open -p3031 --script-timeout 1m --script=eppc-enum-processes --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-3031.txt
fi

if [[ -e $name/3260.txt ]]; then
     echo "     iSCSI"
     nmap -iL $name/3260.txt -Pn -n --open -p3260 --script-timeout 1m --script=iscsi-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-3260.txt
fi

if [[ -e $name/3306.txt ]]; then
     echo "     MySQL"
     nmap -iL $name/3306.txt -Pn -n --open -p3306 --script-timeout 1m --script=mysql-databases,mysql-empty-password,mysql-info,mysql-users,mysql-variables --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-3306.txt
fi

if [[ -e $name/3310.txt ]]; then
     echo "     ClamAV"
     nmap -iL $name/3310.txt -Pn -n --open -p3310 --script-timeout 1m --script=clamav-exec --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 > $name/script-3310.txt
fi

if [[ -e $name/3389.txt ]]; then
     echo "     Remote Desktop"
     nmap -iL $name/3389.txt -Pn -n --open -p3389 --script-timeout 1m --script=rdp-vuln-ms12-020,rdp-enum-encryption --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     egrep -v '(attackers|Description|Disclosure|http|References|Risk factor)' tmp4 > $name/script-3389.txt
fi

if [[ -e $name/3478.txt ]]; then
     echo "     STUN"
     nmap -iL $name/3478.txt -Pn -n -sU --open -p3478 --script-timeout 1m --script=stun-version --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-3478.txt
fi

if [[ -e $name/3632.txt ]]; then
     echo "     Distributed Compiler Daemon"
     nmap -iL $name/3632.txt -Pn -n --open -p3632 --script-timeout 1m --script=distcc-cve2004-2687 --script-args="distcc-exec.cmd='id'" --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     egrep -v '(Allows|Description|Disclosure|earlier|Extra|http|IDs|References|Risk factor)' tmp4 > $name/script-3632.txt
fi

if [[ -e $name/3671.txt ]]; then
     echo "     KNX gateway"
     nmap -iL $name/3671.txt -Pn -n -sU --open -p3671 --script-timeout 1m --script=knx-gateway-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-3671.txt
fi

if [[ -e $name/4369.txt ]]; then
     echo "     Erlang Port Mapper"
     nmap -iL $name/4369.txt -Pn -n --open -p4369 --script-timeout 1m --script=epmd-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-4369.txt
fi

if [[ -e $name/5019.txt ]]; then
     echo "     Versant"
     nmap -iL $name/5019.txt -Pn -n --open -p5019 --script-timeout 1m --script=versant-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-5019.txt
fi

if [[ -e $name/5060.txt ]]; then
     echo "     SIP"
     nmap -iL $name/5060.txt -Pn -n --open -p5060 --script-timeout 1m --script=sip-enum-users,sip-methods --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-5060.txt
fi

if [[ -e $name/5353.txt ]]; then
     echo "     DNS Service Discovery"
     nmap -iL $name/5353.txt -Pn -n -sU --open -p5353 --script-timeout 1m --script=dns-service-discovery --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-5353.txt
fi

if [[ -e $name/5666.txt ]]; then
     echo "     Nagios"
     nmap -iL $name/5666.txt -Pn -n --open -p5666 --script-timeout 1m --script=nrpe-enum --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-5666.txt
fi

if [[ -e $name/5672.txt ]]; then
     echo "     AMQP"
     nmap -iL $name/5672.txt -Pn -n --open -p5672 --script-timeout 1m --script=amqp-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-5672.txt
fi

if [[ -e $name/5683.txt ]]; then
     echo "     CoAP"
     nmap -iL $name/5683.txt -Pn -n -sU --open -p5683 --script-timeout 1m --script=coap-resources --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-5683.txt
fi

if [[ -e $name/5850.txt ]]; then
     echo "     OpenLookup"
     nmap -iL $name/5850.txt -Pn -n --open -p5850 --script-timeout 1m --script=openlookup-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-5850.txt
fi

if [[ -e $name/5900.txt ]]; then
     echo "     VNC"
     nmap -iL $name/5900.txt -Pn -n --open -p5900 --script-timeout 1m --script=realvnc-auth-bypass,vnc-info,vnc-title --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-5900.txt
fi

if [[ -e $name/5984.txt ]]; then
     echo "     CouchDB"
     nmap -iL $name/5984.txt -Pn -n --open -p5984 --script-timeout 1m --script=couchdb-databases,couchdb-stats --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-5984.txt
fi

if [[ -e $name/x11.txt ]]; then
     echo "     X11"
     nmap -iL $name/x11.txt -Pn -n --open -p6000-6005 --script-timeout 1m --script=x11-access --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-x11.txt
fi

if [[ -e $name/6379.txt ]]; then
     echo "     Redis"
     nmap -iL $name/6379.txt -Pn -n --open -p6379 --script-timeout 1m --script=redis-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-6379.txt
fi

if [[ -e $name/6481.txt ]]; then
     echo "     Sun Service Tags"
     nmap -iL $name/6481.txt -Pn -n -sU --open -p6481 --script-timeout 1m --script=servicetags --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-6481.txt
fi

if [[ -e $name/6666.txt ]]; then
     echo "     Voldemort"
     nmap -iL $name/6666.txt -Pn -n --open -p6666 --script-timeout 1m --script=voldemort-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-6666.txt
fi

if [[ -e $name/7210.txt ]]; then
     echo "     Max DB"
     nmap -iL $name/7210.txt -Pn -n --open -p7210 --script-timeout 1m --script=maxdb-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-7210.txt
fi

if [[ -e $name/7634.txt ]]; then
     echo "     Hard Disk Info"
     nmap -iL $name/7634.txt -Pn -n --open -p7634 --script-timeout 1m --script=hddtemp-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-7634.txt
fi

if [[ -e $name/8000.txt ]]; then
     echo "     QNX QCONN"
     nmap -iL $name/8000.txt -Pn -n --open -p8000 --script-timeout 1m --script=qconn-exec --script-args=qconn-exec.timeout=60,qconn-exec.bytes=1024,qconn-exec.cmd="uname -a" --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-8000.txt
fi

if [[ -e $name/8009.txt ]]; then
     echo "     AJP"
     nmap -iL $name/8009.txt -Pn -n --open -p8009 --script-timeout 1m --script=ajp-methods,ajp-request --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-8009.txt
fi

if [[ -e $name/8081.txt ]]; then
     echo "     McAfee ePO"
     nmap -iL $name/8081.txt -Pn -n --open -p8081 --script-timeout 1m --script=mcafee-epo-agent --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-8081.txt
fi

if [[ -e $name/8091.txt ]]; then
     echo "     CouchBase Web Administration"
     nmap -iL $name/8091.txt -Pn -n --open -p8091 --script-timeout 1m --script=membase-http-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-8091.txt
fi

if [[ -e $name/8140.txt ]]; then
     echo "     Puppet"
     nmap -iL $name/8140.txt -Pn -n --open -p8140 --script-timeout 1m --script=puppet-naivesigning --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-8140.txt
fi

if [[ -e $name/bitcoin.txt ]]; then
     echo "     Bitcoin"
     nmap -iL $name/bitcoin.txt -Pn -n --open -p8332,8333 --script-timeout 1m --script=bitcoin-getaddr,bitcoin-info,bitcoinrpc-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-bitcoin.txt
fi

if [[ -e $name/9100.txt ]]; then
     echo "     Lexmark"
     nmap -iL $name/9100.txt -Pn -n --open -p9100 --script-timeout 1m --script=lexmark-config --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-9100.txt
fi

if [[ -e $name/9160.txt ]]; then
     echo "     Cassandra"
     nmap -iL $name/9160.txt -Pn -n --open -p9160 --script-timeout 1m --script=cassandra-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-9160.txt
fi

if [[ -e $name/9600.txt ]]; then
     echo "     FINS"
     nmap -iL $name/9600.txt -Pn -n --open -p9600 --script-timeout 1m --script=omron-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-9600.txt
fi

if [[ -e $name/9999.txt ]]; then
     echo "     Java Debug Wire Protocol"
     nmap -iL $name/9999.txt -Pn -n --open -p9999 --script-timeout 1m --script=jdwp-version --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-9999.txt
fi

if [[ -e $name/10000.txt ]]; then
     echo "     Network Data Management"
     nmap -iL $name/10000.txt -Pn -n --open -p10000 --script-timeout 1m --script=ndmp-fs-info,ndmp-version --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-10000.txt
fi

if [[ -e $name/11211.txt ]]; then
     echo "     Memory Object Caching"
     nmap -iL $name/11211.txt -Pn -n --open -p11211 --script-timeout 1m --script=memcached-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-11211.txt
fi

if [[ -e $name/12000.txt ]]; then
     echo "     CCcam"
     nmap -iL $name/12000.txt -Pn -n --open -p12000 --script-timeout 1m --script=cccam-version --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-12000.txt
fi

if [[ -e $name/12345.txt ]]; then
     echo "     NetBus"
     nmap -iL $name/12345.txt -Pn -n --open -p12345 --script-timeout 1m --script=netbus-auth-bypass,netbus-version --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-12345.txt
fi

if [[ -e $name/17185.txt ]]; then
     echo "     VxWorks"
     nmap -iL $name/17185.txt -Pn -n -sU --open -p17185 --script-timeout 1m --script=wdb-version --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-17185.txt
fi

if [[ -e $name/19150.txt ]]; then
     echo "     GKRellM"
     nmap -iL $name/19150.txt -Pn -n --open -p19150 --script-timeout 1m --script=gkrellm-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-19150.txt
fi

if [[ -e $name/27017.txt ]]; then
     echo "     MongoDB"
     nmap -iL $name/27017.txt -Pn -n --open -p27017 --script-timeout 1m --script=mongodb-databases,mongodb-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-27017.txt
fi

if [[ -e $name/31337.txt ]]; then
     echo "     BackOrifice"
     nmap -iL $name/31337.txt -Pn -n -sU --open -p31337 --script-timeout 1m --script=backorifice-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-31337.txt
fi

if [[ -e $name/35871.txt ]]; then
     echo "     Flume"
     nmap -iL $name/35871.txt -Pn -n --open -p35871 --script-timeout 1m --script=flume-master-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-35871.txt
fi

if [[ -e $name/44818.txt ]]; then
     echo "     EtherNet/IP"
     nmap -iL $name/44818.txt -Pn -n -sU --open -p44818 --script-timeout 1m --script=enip-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-44818.txt
fi

if [[ -e $name/47808.txt ]]; then
     echo "     BACNet"
     nmap -iL $name/47808.txt -Pn -n -sU --open -p47808 --script-timeout 1m --script=bacnet-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-47808.txt
fi

if [[ -e $name/49152.txt ]]; then
     echo "     Supermicro"
     nmap -iL $name/49152.txt -Pn -n --open -p49152 --script-timeout 1m --script=supermicro-ipmi-conf --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-49152.txt
fi

if [[ -e $name/50000.txt ]]; then
     echo "     DRDA"
     nmap -iL $name/50000.txt -Pn -n --open -p50000 --script-timeout 1m --script=drda-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-50000.txt
fi

if [[ -e $name/hadoop.txt ]]; then
     echo "     Hadoop"
     nmap -iL $name/hadoop.txt -Pn -n --open -p50030,50060,50070,50075,50090 --script-timeout 1m --script=hadoop-datanode-info,hadoop-jobtracker-info,hadoop-namenode-info,hadoop-secondary-namenode-info,hadoop-tasktracker-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-hadoop.txt
fi

if [[ -e $name/apache-hbase.txt ]]; then
     echo "     Apache HBase"
     nmap -iL $name/apache-hbase.txt -Pn -n --open -p60010,60030 --script-timeout 1m --script=hbase-master-info,hbase-region-info --min-hostgroup 100 -g $sourceport --scan-delay $delay > tmp
     f_cleanup
     mv tmp4 $name/script-apache-hbase.txt
fi

rm tmp*

for x in $name/./script*; do
     if grep '|' $x > /dev/null 2>&1; then
          echo > /dev/null 2>&1
     else
          rm $x > /dev/null 2>&1
     fi
done

##############################################################################################################

# Additional tools

if [[ -e $name/161.txt ]]; then
     onesixtyone -c /usr/share/doc/onesixtyone/dict.txt -i $name/161.txt > $name/onesixtyone.txt
fi

if [ -e $name/445.txt ] || [ -e $name/500.txt ]; then
     echo
     echo $medium
     echo
     echo -e "${BLUE}Running additional tools.${NC}"
fi

if [[ -e $name/445.txt ]]; then
     echo "     enum4linux"
     for i in $(cat $name/445.txt); do
          enum4linux -a $i | egrep -v "(Can't determine|enum4linux|Looking up status|No printers|No reply from|unknown|[E])" > tmp
          cat -s tmp >> $name/script-enum4linux.txt
     done
fi

if [[ -e $name/445.txt ]]; then
     echo "     smbclient"
     for i in $(cat $name/445.txt); do
          echo $i >> $name/script-smbclient.txt
          smbclient -L $i -N | grep -v 'failed' >> $name/script-smbclient.txt 2>/dev/null
          echo >> $name/script-smbclient.txt
     done
fi

if [[ -e $name/500.txt ]]; then
     echo "     ike-scan"
     for i in $(cat $name/445.txt); do
          ike-scan -f $i >> $name/script-ike-scan.txt
     done
fi

rm tmp 2>/dev/null
}

##############################################################################################################

f_metasploit(){
echo
echo -n "Run matching Metasploit auxiliaries? (y/N) "
read msf
}

##############################################################################################################

f_run-metasploit(){
if [ "$msf" == "y" ]; then
     echo
     echo -e "${BLUE}Starting Postgres.${NC}"
     service postgresql start

     echo
     echo -e "${BLUE}Starting Metasploit.${NC}"
     echo
     echo -e "${BLUE}Using the following resource files.${NC}"
     cp -R $discover/resource/ /tmp/

     echo workspace -a $name > /tmp/master
     echo spool tmpmsf > /tmp/master

     if [[ -e $name/19.txt ]]; then
          echo "     Chargen Probe Utility"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/19.txt|g" /tmp/resource/19-chargen.rc
          cat /tmp/resource/19-chargen.rc >> /tmp/master
     fi

     if [[ -e $name/21.txt ]]; then
          echo "     FTP"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/21.txt|g" /tmp/resource/21-ftp.rc
          cat /tmp/resource/21-ftp.rc >> /tmp/master
     fi

     if [[ -e $name/22.txt ]]; then
          echo "     SSH"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/22.txt|g" /tmp/resource/22-ssh.rc
          cat /tmp/resource/22-ssh.rc >> /tmp/master
     fi

     if [[ -e $name/23.txt ]]; then
          echo "     Telnet"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/23.txt|g" /tmp/resource/23-telnet.rc
          cat /tmp/resource/23-telnet.rc >> /tmp/master
     fi

     if [[ -e $name/25.txt ]]; then
          echo "     SMTP"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/25.txt|g" /tmp/resource/25-smtp.rc
          cat /tmp/resource/25-smtp.rc >> /tmp/master
     fi

     if [[ -e $name/69.txt ]]; then
          echo "     TFTP"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/69.txt|g" /tmp/resource/69-tftp.rc
          cat /tmp/resource/69-tftp.rc >> /tmp/master
     fi

     if [[ -e $name/79.txt ]]; then
          echo "     Finger"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/79.txt|g" /tmp/resource/79-finger.rc
          cat /tmp/resource/79-finger.rc >> /tmp/master
     fi

     if [[ -e $name/110.txt ]]; then
          echo "     POP3"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/110.txt|g" /tmp/resource/110-pop3.rc
          cat /tmp/resource/110-pop3.rc >> /tmp/master
     fi

     if [[ -e $name/111.txt ]]; then
          echo "     RPC"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/111.txt|g" /tmp/resource/111-rpc.rc
          cat /tmp/resource/111-rpc.rc >> /tmp/master
     fi

     if [[ -e $name/123.txt ]]; then
          echo "     NTP"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/123.txt|g" /tmp/resource/123-udp-ntp.rc
          cat /tmp/resource/123-udp-ntp.rc >> /tmp/master
     fi

     if [[ -e $name/135.txt ]]; then
          echo "     DCE/RPC"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/135.txt|g" /tmp/resource/135-dcerpc.rc
          cat /tmp/resource/135-dcerpc.rc >> /tmp/master
     fi

     if [[ -e $name/137.txt ]]; then
          echo "     NetBIOS"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/137.txt|g" /tmp/resource/137-udp-netbios.rc
          cat /tmp/resource/137-udp-netbios.rc >> /tmp/master
     fi

     if [[ -e $name/143.txt ]]; then
          echo "     IMAP"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/143.txt|g" /tmp/resource/143-imap.rc
          cat /tmp/resource/143-imap.rc >> /tmp/master
     fi

     if [[ -e $name/161.txt ]]; then
          echo "     SNMP"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/161.txt|g" /tmp/resource/161-udp-snmp.rc
          cat /tmp/resource/161-udp-snmp.rc >> /tmp/master
     fi

     if [[ -e $name/407.txt ]]; then
          echo "     Motorola"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/407.txt|g" /tmp/resource/407-udp-motorola.rc
          cat /tmp/resource/407-udp-motorola.rc >> /tmp/master
     fi

     if [[ -e $name/443.txt ]]; then
          echo "     VMware"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/443.txt|g" /tmp/resource/443-vmware.rc
          cat /tmp/resource/443-vmware.rc >> /tmp/master
     fi

     if [[ -e $name/445.txt ]]; then
          echo "     SMB"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/445.txt|g" /tmp/resource/445-smb.rc
          cat /tmp/resource/445-smb.rc >> /tmp/master
     fi

     if [[ -e $name/465.txt ]]; then
          echo "     SMTP/S"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/465.txt|g" /tmp/resource/465-smtp.rc
          cat /tmp/resource/465-smtp.rc >> /tmp/master
     fi

     if [[ -e $name/502.txt ]]; then
          echo "     SCADA Modbus Client Utility"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/502.txt|g" /tmp/resource/502-scada.rc
          cat /tmp/resource/502-scada.rc >> /tmp/master
     fi

     if [[ -e $name/512.txt ]]; then
          echo "     Rexec"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/512.txt|g" /tmp/resource/512-rexec.rc
          cat /tmp/resource/512-rexec.rc >> /tmp/master
     fi

     if [[ -e $name/513.txt ]]; then
          echo "     rlogin"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/513.txt|g" /tmp/resource/513-rlogin.rc
          cat /tmp/resource/513-rlogin.rc >> /tmp/master
     fi

     if [[ -e $name/514.txt ]]; then
          echo "     rshell"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/514.txt|g" /tmp/resource/514-rshell.rc
          cat /tmp/resource/514-rshell.rc >> /tmp/master
     fi

     if [[ -e $name/523.txt ]]; then
          echo "     db2"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/523.txt|g" /tmp/resource/523-udp-db2.rc
          cat /tmp/resource/523-udp-db2.rc >> /tmp/master
     fi

     if [[ -e $name/548.txt ]]; then
          echo "     AFP"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/548.txt|g" /tmp/resource/548-afp.rc
          cat /tmp/resource/548-afp.rc >> /tmp/master
     fi

     if [[ -e $name/623.txt ]]; then
          echo "     IPMI"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/623.txt|g" /tmp/resource/623-udp-ipmi.rc
          cat /tmp/resource/623-udp-ipmi.rc >> /tmp/master
     fi

     if [[ -e $name/771.txt ]]; then
          echo "     SCADA Digi"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/771.txt|g" /tmp/resource/771-scada.rc
          cat /tmp/resource/771-scada.rc >> /tmp/master
     fi

     if [[ -e $name/831.txt ]]; then
          echo "     EasyCafe Server Remote File Access"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/831.txt|g" /tmp/resource/831-easycafe.rc
          cat /tmp/resource/831-easycafe.rc >> /tmp/master
     fi

     if [[ -e $name/902.txt ]]; then
          echo "     VMware"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/902.txt|g" /tmp/resource/902-vmware.rc
          cat /tmp/resource/902-vmware.rc >> /tmp/master
     fi

     if [[ -e $name/998.txt ]]; then
          echo "     Novell ZENworks Configuration Management Preboot Service Remote File Access"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/998.txt|g" /tmp/resource/998-zenworks.rc
          cat /tmp/resource/998-zenworks.rc >> /tmp/master
     fi

     if [[ -e $name/1099.txt ]]; then
          echo "     RMI Registery"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/1099.txt|g" /tmp/resource/1099-rmi.rc
          cat /tmp/resource/1099-rmi.rc >> /tmp/master
     fi

     if [[ -e $name/1158.txt ]]; then
          echo "     Oracle"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/1158.txt|g" /tmp/resource/1158-oracle.rc
          cat /tmp/resource/1158-oracle.rc >> /tmp/master
     fi

     if [[ -e $name/1433.txt ]]; then
          echo "     MS-SQL"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/1433.txt|g" /tmp/resource/1433-mssql.rc
          cat /tmp/resource/1433-mssql.rc >> /tmp/master
     fi

     if [[ -e $name/1521.txt ]]; then
          echo "     Oracle"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/1521.txt|g" /tmp/resource/1521-oracle.rc
          cat /tmp/resource/1521-oracle.rc >> /tmp/master
     fi

     if [[ -e $name/1604.txt ]]; then
          echo "     Citrix"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/1604.txt|g" /tmp/resource/1604-udp-citrix.rc
          cat /tmp/resource/1604-udp-citrix.rc >> /tmp/master
     fi

     if [[ -e $name/1720.txt ]]; then
          echo "     H323"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/1720.txt|g" /tmp/resource/1720-h323.rc
          cat /tmp/resource/1720-h323.rc >> /tmp/master
     fi

     if [[ -e $name/1900.txt ]]; then
          echo "     UPnP"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/1900.txt|g" /tmp/resource/1900-udp-upnp.rc
          cat /tmp/resource/1900-udp-upnp.rc >> /tmp/master
     fi

     if [[ -e $name/2049.txt ]]; then
          echo "     NFS"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/2049.txt|g" /tmp/resource/2049-nfs.rc
          cat /tmp/resource/2049-nfs.rc >> /tmp/master
     fi

     if [[ -e $name/2362.txt ]]; then
          echo "     SCADA Digi"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/2362.txt|g" /tmp/resource/2362-udp-scada.rc
          cat /tmp/resource/2362-udp-scada.rc >> /tmp/master
     fi

     if [[ -e $name/3000.txt ]]; then
          echo "     EMC"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/3000.txt|g" /tmp/resource/3000-emc.rc
          cat /tmp/resource/3000-emc.rc >> /tmp/master
     fi

     if [[ -e $name/3050.txt ]]; then
          echo "     Borland InterBase Services Manager Information"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/3050.txt|g" /tmp/resource/3050-borland.rc
          cat /tmp/resource/3050-borland.rc >> /tmp/master
     fi

     if [[ -e $name/3306.txt ]]; then
          echo "     MySQL"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/3306.txt|g" /tmp/resource/3306-mysql.rc
          cat /tmp/resource/3306-mysql.rc >> /tmp/master
     fi

     if [[ -e $name/3310.txt ]]; then
          echo "     ClamAV"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/3310.txt|g" /tmp/resource/3310-clamav.rc
          cat /tmp/resource/3310-clamav.rc >> /tmp/master
     fi

     if [[ -e $name/3389.txt ]]; then
          echo "     RDP"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/3389.txt|g" /tmp/resource/3389-rdp.rc
          cat /tmp/resource/3389-rdp.rc >> /tmp/master
     fi

     if [[ -e $name/3500.txt ]]; then
          echo "     EMC"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/3500.txt|g" /tmp/resource/3500-emc.rc
          cat /tmp/resource/3500-emc.rc >> /tmp/master
     fi

     if [[ -e $name/4800.txt ]]; then
          echo "     Moxa"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/4800.txt|g" /tmp/resource/4800-udp-moxa.rc
          cat /tmp/resource/4800-udp-moxa.rc >> /tmp/master
     fi

     if [[ -e $name/5000.txt ]]; then
          echo "     Satel"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5000.txt|g" /tmp/resource/5000-satel.rc
          cat /tmp/resource/5000-satel.rc >> /tmp/master
     fi

     if [[ -e $name/5040.txt ]]; then
          echo "     DCE/RPC"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5040.txt|g" /tmp/resource/5040-dcerpc.rc
          cat /tmp/resource/5040-dcerpc.rc >> /tmp/master
     fi

     if [[ -e $name/5060.txt ]]; then
          echo "     SIP UDP"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5060.txt|g" /tmp/resource/5060-udp-sip.rc
          cat /tmp/resource/5060-udp-sip.rc >> /tmp/master
     fi

     if [[ -e $name/5060-tcp.txt ]]; then
          echo "     SIP"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5060-tcp.txt|g" /tmp/resource/5060-sip.rc
          cat /tmp/resource/5060-sip.rc >> /tmp/master
     fi

     if [[ -e $name/5432.txt ]]; then
          echo "     Postgres"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5432.txt|g" /tmp/resource/5432-postgres.rc
          cat /tmp/resource/5432-postgres.rc >> /tmp/master
     fi

     if [[ -e $name/5560.txt ]]; then
          echo "     Oracle iSQL"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5560.txt|g" /tmp/resource/5560-oracle.rc
          cat /tmp/resource/5560-oracle.rc >> /tmp/master
     fi

     if [[ -e $name/5631.txt ]]; then
          echo "     pcAnywhere"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5631.txt|g" /tmp/resource/5631-pcanywhere.rc
          cat /tmp/resource/5631-pcanywhere.rc >> /tmp/master
     fi

     if [[ -e $name/5632.txt ]]; then
          echo "     pcAnywhere"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5632.txt|g" /tmp/resource/5632-pcanywhere.rc
          cat /tmp/resource/5632-pcanywhere.rc >> /tmp/master
     fi

     if [[ -e $name/5900.txt ]]; then
          echo "     VNC"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5900.txt|g" /tmp/resource/5900-vnc.rc
          cat /tmp/resource/5900-vnc.rc >> /tmp/master
     fi

     if [[ -e $name/5920.txt ]]; then
          echo "     CCTV DVR"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5920.txt|g" /tmp/resource/5920-cctv.rc
          cat /tmp/resource/5920-cctv.rc >> /tmp/master
     fi

     if [[ -e $name/5984.txt ]]; then
          echo "     CouchDB"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5984.txt|g" /tmp/resource/5984-couchdb.rc
          cat /tmp/resource/5984-couchdb.rc >> /tmp/master
     fi

     if [[ -e $name/5985.txt ]]; then
          echo "     winrm"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/5985.txt|g" /tmp/resource/5985-winrm.rc
          cat /tmp/resource/5985-winrm.rc >> /tmp/master
     fi

     if [[ -e $name/x11.txt ]]; then
          echo "     x11"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/x11.txt|g" /tmp/resource/6000-5-x11.rc
          cat /tmp/resource/6000-5-x11.rc >> /tmp/master
     fi

     if [[ -e $name/6379.txt ]]; then
          echo "     Redis"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/6379.txt|g" /tmp/resource/6379-redis.rc
          cat /tmp/resource/6379-redis.rc >> /tmp/master
     fi

     if [[ -e $name/7777.txt ]]; then
          echo "     Backdoor"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/7777.txt|g" /tmp/resource/7777-backdoor.rc
          cat /tmp/resource/7777-backdoor.rc >> /tmp/master
     fi

     if [[ -e $name/8000.txt ]]; then
          echo "     Canon"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/8000.txt|g" /tmp/resource/8000-canon.rc
          cat /tmp/resource/8000-canon.rc >> /tmp/master
     fi

     if [[ -e $name/8080.txt ]]; then
          echo "     Tomcat"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/8080.txt|g" /tmp/resource/8080-tomcat.rc
          cat /tmp/resource/8080-tomcat.rc >> /tmp/master
     fi

     if [[ -e $name/8080.txt ]]; then
          echo "     Oracle"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/8080.txt|g" /tmp/resource/8080-oracle.rc
          cat /tmp/resource/8080-oracle.rc >> /tmp/master
     fi

     if [[ -e $name/8222.txt ]]; then
          echo "     VMware"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/8222.txt|g" /tmp/resource/8222-vmware.rc
          cat /tmp/resource/8222-vmware.rc >> /tmp/master
     fi

     if [[ -e $name/8400.txt ]]; then
          echo "     Adobe"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/8400.txt|g" /tmp/resource/8400-adobe.rc
          cat /tmp/resource/8400-adobe.rc >> /tmp/master
     fi

     if [[ -e $name/8834.txt ]]; then
          echo "     Nessus"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/8834.txt|g" /tmp/resource/8834-nessus.rc
          cat /tmp/resource/8834-nessus.rc >> /tmp/master
     fi

     if [[ -e $name/9000.txt ]]; then
          echo "     Sharp DVR Password Retriever"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/9000.txt|g" /tmp/resource/9000-sharp.rc
          cat /tmp/resource/9000-sharp.rc >> /tmp/master
     fi

     if [[ -e $name/9084.txt ]]; then
          echo "     VMware"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/9084.txt|g" /tmp/resource/9084-vmware.rc
          cat /tmp/resource/9084-vmware.rc >> /tmp/master
     fi

     if [[ -e $name/9100.txt ]]; then
          echo "     Printers"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/9100.txt|g" /tmp/resource/9100-printers.rc
          cat /tmp/resource/9100-printers.rc >> /tmp/master
     fi

     if [[ -e $name/9999.txt ]]; then
          echo "     Telnet"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/9999.txt|g" /tmp/resource/9999-telnet.rc
          cat /tmp/resource/9999-telnet.rc >> /tmp/master
     fi

     if [[ -e $name/13364.txt ]]; then
          echo "     Rosewill RXS-3211 IP Camera Password Retriever"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/13364.txt|g" /tmp/resource/13364-rosewill.rc
          cat /tmp/resource/13364-rosewill.rc >> /tmp/master
     fi

     if [[ -e $name/17185.txt ]]; then
          echo "     VxWorks"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/17185.txt|g" /tmp/resource/17185-udp-vxworks.rc
          cat /tmp/resource/17185-udp-vxworks.rc >> /tmp/master
     fi

     if [[ -e $name/28784.txt ]]; then
          echo "     SCADA Koyo DirectLogic PLC"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/28784.txt|g" /tmp/resource/28784-scada.rc
          cat /tmp/resource/28784-scada.rc >> /tmp/master
     fi

     if [[ -e $name/30718.txt ]]; then
          echo "     Telnet"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/30718.txt|g" /tmp/resource/30718-telnet.rc
          cat /tmp/resource/30718-telnet.rc >> /tmp/master
     fi

     if [[ -e $name/37777.txt ]]; then
          echo "     Dahua DVR"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/37777.txt|g" /tmp/resource/37777-dahua-dvr.rc
          cat /tmp/resource/37777-dahua-dvr.rc >> /tmp/master
     fi

     if [[ -e $name/46824.txt ]]; then
          echo "     SCADA Sielco Sistemi"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/46824.txt|g" /tmp/resource/46824-scada.rc
          cat /tmp/resource/46824-scada.rc >> /tmp/master
     fi

     if [[ -e $name/50000.txt ]]; then
          echo "     db2"
          sed -i "s|setg RHOSTS.*|setg RHOSTS file:$name\/50000.txt|g" /tmp/resource/50000-db2.rc
          cat /tmp/resource/50000-db2.rc >> /tmp/master
     fi

     echo db_export -f xml -a $name/metasploit.xml >> /tmp/master
     echo exit >> /tmp/master

     x=$(wc -l /tmp/master | cut -d ' ' -f1)

     if [ $x -eq 3 ]; then
          echo 2>/dev/null
     else
          echo
          sed 's/\/\//\//g' /tmp/master > $name/master.rc
          msfdb init
          msfconsole -r $name/master.rc
          cat tmpmsf | egrep -iv "(> exit|> run|% complete|attempting to extract|authorization not requested|checking if file|completed|connecting to the server|connection reset by peer|data_connect failed|db_export|did not reply|does not appear|doesn't exist|finished export|handshake failed|ineffective|it doesn't seem|login fail|negotiation failed|nomethoderror|no relay detected|no response|No users found|not be identified|not foundnot vulnerable|providing some time|request timeout|responded with error|rport|rhosts|scanning for vulnerable|shutting down the tftp|spooling|starting export|starting tftp server|starting vnc login|threads|timed out|trying to acquire|unable to|unknown state)" > $name/metasploit.txt
          rm $name/master.rc
          rm tmpmsf
     fi
fi
}

##############################################################################################################

f_enumerate(){
clear
f_banner
f_typeofscan

echo -n "Enter the location of your previous scan: "
read -e location

# Check for no answer
if [[ -z $location ]]; then
     f_error
fi

# Check for wrong answer
if [ ! -d $location ]; then
     f_error
fi

name=$location

echo
echo -n "Set scan delay. (0-5, enter for normal) "
read delay

# Check for no answer
if [[ -z $delay ]]; then
     delay='0'
fi

if [ $delay -lt 0 ] || [ $delay -gt 5 ]; then
     f_error
fi

f_scripts
echo
echo $medium
f_run-metasploit

echo
echo -e "${BLUE}Stopping Postgres.${NC}"
service postgresql stop

echo
echo $medium
echo
echo "***Scan complete.***"
echo
echo
echo -e "The supporting data folder is located at ${YELLOW}$name${NC}\n"
echo
echo
exit
}

##############################################################################################################

f_report(){
END=$(date +%r\ %Z)
filename=$name/report.txt
host=$(wc -l $name/hosts.txt | cut -d ' ' -f1)

echo "Nmap Report" > $filename
date +%A" - "%B" "%d", "%Y >> $filename
echo >> $filename
echo "Start time   $START" >> $filename
echo "Finish time  $END" >> $filename
echo "Scanner IP   $ip" >> $filename
echo >> $filename
echo $medium >> $filename
echo >> $filename

if [ -e $name/script-smbvulns.txt ]; then
     echo "May be vulnerable to MS08-067 & more." >> $filename
     echo >> $filename
     cat $name/script-smbvulns.txt >> $filename
     echo >> $filename
     echo $medium >> $filename
     echo >> $filename
fi

echo "Hosts Discovered ($host)" >> $filename
echo >> $filename
cat $name/hosts.txt >> $filename 2>/dev/null
echo >> $filename

if [[ ! -s $name/ports.txt ]]; then
     rm -rf "$name" tmp*
     echo
     echo $medium
     echo
     echo "***Scan complete.***"
     echo
     echo
     echo -e "${YELLOW}No hosts found with open ports.${NC}"
     echo
     echo
     exit
else
     ports=$(wc -l $name/ports.txt | cut -d ' ' -f1)
fi

echo $medium >> $filename
echo >> $filename
echo "Open Ports ($ports)" >> $filename
echo >> $filename

if [ -s $name/ports-tcp.txt ]; then
     echo "TCP Ports" >> $filename
     cat $name/ports-tcp.txt >> $filename
     echo >> $filename
fi

if [ -s $name/ports-udp.txt ]; then
     echo "UDP Ports" >> $filename
     cat $name/ports-udp.txt >> $filename
     echo >> $filename
fi

echo $medium >> $filename

if [ -e $name/banners.txt ]; then
     banners=$(wc -l $name/banners.txt | cut -d ' ' -f1)
     echo >> $filename
     echo "Banners ($banners)" >> $filename
     echo >> $filename
     cat $name/banners.txt >> $filename
     echo >> $filename
     echo $medium >> $filename
fi

echo >> $filename
echo "High Value Hosts by Port" >> $filename
echo >> $filename

HVPORTS="13 19 21 22 23 25 37 53 67 69 70 79 80 102 110 111 119 123 135 137 139 143 161 389 407 433 443 445 465 500 502 512 513 514 523 524 548 554 563 587 623 631 636 771 831 873 902 993 995 998 1050 1080 1099 1158 1344 1352 1433 1434 1521 1604 1720 1723 1883 1900 1911 1962 2049 2202 2302 2362 2375 2628 2947 3000 3031 3050 3260 3306 3310 3389 3478 3500 3632 3671 4369 4800 5019 5040 5060 5353 5432 5560 5631 5632 5666 5672 5683 5850 5900 5920 5984 5985 6000 6001 6002 6003 6004 6005 6379 6481 6666 7210 7634 7777 8000 8009 8080 8081 8091 8140 8222 8332 8333 8400 8443 8834 9000 9084 9100 9160 9600 9999 10000 11211 12000 12345 13364 17185 19150 27017 28784 30718 31337 35871 37777 44818 46824 47808 49152 50000 50030 50060 50070 50075 50090 60010 60030"

for i in $HVPORTS; do
     if [[ -e $name/$i.txt ]]; then
          echo "Port $i" >> $filename
          cat $name/$i.txt >> $filename
          echo >> $filename
     fi
done

echo $medium >> $filename
echo >> $filename
cat $name/nmap.txt >> $filename
echo $medium >> $filename
echo $medium >> $filename
echo >> $filename
echo "Nmap Scripts" >> $filename

SCRIPTS="script-13 script-21 script-22 script-23 script-smtp script-37 script-53 script-67 script-70 script-79 script-102 script-110 script-111 script-nntp script-123 script-137 script-139 script-143 script-161 script-389 script-443 script-445 script-500 script-523 script-524 script-548 script-554 script-623 script-631 script-636 script-873 script-993 script-995 script-1050 script-1080 script-1099 script-1344 script-1352 script-1433 script-1434 script-1521 script-1604 script-1723 script-1883 script-1911 script-1962 script-2049 script-2202 script-2302 script-2375 script-2628 script-2947 script-3031 script-3260 script-3306 script-3310 script-3389 script-3478 script-3632 script-3671 script-4369 script-5019 script-5060 script-5353 script-5666 script-5672 script-5683 script-5850 script-5900 script-5984 script-x11 script-6379 script-6481 script-6666 script-7210 script-7634 script-8000 script-8009 script-8081 script-8091 script-8140 script-bitcoin script-9100 script-9160 script-9600 script-9999 script-10000 script-11211 script-12000 script-12345 script-17185 script-19150 script-27017 script-31337 script-35871 script-44818 script-47808 script-49152 script-50000 script-hadoop script-apache-hbase"

for i in $SCRIPTS; do
     if [[ -e $name/"$i.txt" ]]; then
          cat $name/"$i.txt" >> $filename
          echo $medium >> $filename
     fi
done

if [ -e $name/script-enum4linux.txt ] || [ -e $name/script-smbclient.txt ] || [ -e $name/ike-scan.txt ]; then
     echo $medium >> $filename
     echo >> $filename
     echo "Additional Enumeration" >> $filename

     if [ -e $name/script-enum4linux.txt ]; then
          cat $name/script-enum4linux.txt >> $filename
          echo $medium >> $filename
          echo >> $filename
     fi

     if [ -e $name/script-smbclient.txt ]; then
          cat $name/script-smbclient.txt >> $filename
          echo $medium >> $filename
     fi

     if [ -e $name/script-ike-scan.txt ]; then
          cat $name/script-ike-scan.txt >> $filename
          echo $medium >> $filename
     fi
fi

mv $name $home/data/

START=0
END=0

echo
echo $medium
echo
echo "***Scan complete.***"
echo
echo
echo -e "The new report is located at ${YELLOW}$home/data/$name/report.txt${NC}\n"
echo
echo
exit
}

##############################################################################################################

f_directObjectRef(){
clear
f_banner

echo -e "${BLUE}Using Burp, authenticate to a site, map & Spider, then log out.${NC}"
echo -e "${BLUE}Target > Site map > select the URL > right click > Copy URLs in this host.${NC}"
echo -e "${BLUE}Paste the results into a new file.${NC}"

f_location

for i in $(cat $location); do
     curl -sk -w "%{http_code} - %{url_effective} \\n" "$i" -o /dev/null 2>&1 | tee -a tmp
done

cat tmp | sort -u > DirectObjectRef.txt
mv DirectObjectRef.txt $home/data/DirectObjectRef.txt
rm tmp

echo
echo $medium
echo
echo "***Scan complete.***"
echo
echo
echo -e "The new report is located at ${YELLOW}$home/data/DirectObjectRef.txt${NC}\n"
echo
echo
exit
}

##############################################################################################################

f_main(){
clear
f_banner

if [ ! -d $home/data ]; then
     mkdir -p $home/data
fi

echo -e "${BLUE}RECON${NC}"
echo "1.  Domain"
echo "2.  Person"
echo "3.  Parse salesforce"
echo
echo -e "${BLUE}SCANNING${NC}"
echo "4.  Generate target list"
echo "5.  CIDR"
echo "6.  List"
echo "7.  IP, range, or URL"
echo "8.  Rerun Nmap scripts and MSF aux"
echo
echo -e "${BLUE}WEB${NC}"
echo "9.  Insecure direct object reference"
echo "10. Open multiple tabs in Firefox"
echo "11. Nikto"
echo "12. SSL"
echo
echo -e "${BLUE}MISC${NC}"
echo "13. Parse XML"
echo "14. Generate a malicious payload"
echo "15. Start a Metasploit listener"
echo "16. Update"
echo "17. Exit"
echo
echo -n "Choice: "
read choice

case $choice in
     1) f_domain;;
     2) f_person;;
     3) f_salesforce;;
     4) f_generateTargetList;;
     5) f_cidr;;
     6) f_list;;
     7) f_single;;
     8) f_enumerate;;
     9) f_directObjectRef;;
     10) $discover/multiTabs.sh && exit;;
     11) $discover/nikto.sh && exit;;
     12) $discover/ssl.sh && exit;;
     13) $discover/parse.sh && exit;;
     14) $discover/payload.sh && exit;;
     15) $discover/listener.sh && exit;;
     16) $discover/update.sh && exit;;
     17) clear && exit;;
     99) $discover/new-modules.sh && exit;;
     *) f_error;;
esac
}

export -f f_main

##############################################################################################################

while true; do f_main; done

