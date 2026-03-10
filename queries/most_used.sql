SELECT base_cmd, COUNT(*) as count
FROM commands
GROUP BY base_cmd
ORDER BY count DESC
LIMIT 20;
