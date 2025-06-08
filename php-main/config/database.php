<?php
// config/database.php
class Database {
    private $connections = [];
    private $defaultConnection = 'mysql'; // Define la conexión predeterminada

    public function __construct() {
        $this->connections['mysql'] = [
            'host' => 'localhost',
            'db_name' => 'finalboss',
            'username' => 'root',
            'password' => 'password',
            'dsn' => 'mysql:host=localhost;dbname=finalboss;charset=utf8',
        ];

        $this->connections['pgsql'] = [
            'host' => 'db', // Este es el nombre del servicio Docker
            'db_name' => 'sistema_rrhh',
            'username' => 'postgres_user',
            'password' => 'postgres_password',
            'dsn' => 'pgsql:host=db;port=5432;dbname=sistema_rrhh',
        ];
    }

    public function getConnection($type = null) {
        $type = $type ?: $this->defaultConnection;

        if (!isset($this->connections[$type])) {
            throw new Exception("La conexión '{$type}' no está configurada.");
        }

        $config = $this->connections[$type];
        try {
            $conn = new PDO(
                $config['dsn'],
                $config['username'],
                $config['password']
            );
            $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            return $conn;
        } catch (PDOException $exception) {
            echo "Error de conexión ({$type}): " . $exception->getMessage();
        }

        return null;
    }
}
?>
