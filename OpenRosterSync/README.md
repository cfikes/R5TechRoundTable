# Open Roster SFTP AD Sync Tool
 Sync from OpenRoster students.csv export located on SFTP to AD

### Requirements
- Windows 10 or Windows Server
- Active Directory Powershell Module
- WinSCP (Includes 5.17.10 in Repo)
- For automation, task scheduled to call OpenRosterSFTPSync.ps1 with appropriate permissions

### Installation
- Download or clone repository to specified server
- Install WinSCP if not already (5.17.10 DLL and Installation included in repo)
- Run SettingsEditor.ps1 to generate db and configure your settings
- Run either manually OpenRosterSFTPSync.ps1 or schedule a task

# Important Information
OU Search String will search out every ou containing that string. For example, Class would find: Class of 2021, Class of 2022, and so on.  Only those OU's are taken into account. Accounts will not be created unless the OU exist already. OU destination is determined by the graduation year of the student, in the example above, a 12th grader would automatically be placed in the Class of 2021 OU. If you use another search string, the graduation year is still being searched for. This was the best sane effort without involving tons of configuration.

If no home directory is specified, none is created. If a home directory root is specified, folders will be created using the SAMAccount name and the user along with the domain admins group will automatically be granted full control, with no inheritance from the parent.

If no default group is specified, no group is automatically joined. If a group is specified, new accounts will be added to this group. Example a students group.

Accounts found to have a collision will check the name information along with the student id and whether they are disabled. If they all match up, it presumes this is a previos account and updates the information, enabling the account.

If Enable Account Creation is not selected, only reports are generated and no actions are taken place. If Enable Account Creation and Enable Account Suspension, accounts that are present in the OU's searched but not in the open roster file will be disabled.

Reports are emailed to the account specified in the SMTP settings tab, and also copied to the reports directory.

If you desire more features, or want to contribute, please contact cfikes@fikesmedia.com