# Distributed_File_Server

1. File Service implemented with WRITE, READ and LOAD command where READ downloads a file from the file base to create a local client copy. WRITE writes to the local client copy and LOAD uploads the file back to the server.

2. Security Service implemented by means of authentication service prior to issue of commands to the file server. Authentication takes place at authentication node, where asymetric encryption (RSA) is used to encrypt the message after the hashing of the password is completed. This creates  <b>Security transparency</b>.

3. Lock Service implemented by creating another server on a different port that creates <b>Access transparency</b> and synchronises all READs and WRITEs made by the client.

4. Directory Service implemented to navigate around and account for the existing files and files that can be added by the users down the line

Users can create new files and upload them to the server with LOAD command

Default ports and IPs can be changed.
