SELECT command, COUNT(*)
FROM commands
WHERE exit_code != 0
GROUP BY command
ORDER BY COUNT(*) DESC;

