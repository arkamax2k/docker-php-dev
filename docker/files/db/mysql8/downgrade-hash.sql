# Make sure the default authentication method is understood by MySQL client libraries
ALTER USER `testuser`@`%` IDENTIFIED WITH mysql_native_password BY 'testpass';

FLUSH PRIVILEGES;
