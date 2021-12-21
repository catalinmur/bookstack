job "mysql" {
 datacenters = ["dc1"]

  group "database" {

   network {
    mode = "bridge"
    port "db" {
      static = 3306
      to = 3306
      }
    }
     service {
          name = "mariadb"
          port = "3306"
        }

  task "mariadb" {
      driver = "docker"
      config {
         image = "lscr.io/linuxserver/mariadb"
         ports = ["db"]
         }
      env {
           MYSQL_ROOT_PASSWORD = "rootpass"
           MYSQL_DATABASE = "bookstackapp"
           MYSQL_USER = "bookstack"
           MYSQL_PASSWORD = "dbpass"
           }
      resources {
           cpu    = 500
           memory = 256
           }
    }
  }

}
