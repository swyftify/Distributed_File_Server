# Distributed_File_Server

1. File Service implemented with WRITE, READ and LOAD command where READ downloads a file from the file base to create a local client copy. WRITE writes to the local client copy and LOAD uploads the file back to the server.

2. Security Service implemented by means of authentication service prior to issue of commands to the file server. Authentication takes place at authentication node, where asymetric encryption (RSA) is used to encrypt the message after the hashing of the password is completed.
