#!/usr/bin/perl -w

$username="root";
$password="password123";
$cryptedpass=crypt($password,$username);

print "Content-type: text/html\n\n $username|$cryptedpass|3";
open (F,">users.txt");
	print F "$username:$cryptedpass:3";
close (F);