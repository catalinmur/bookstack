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
           MYSQL_ROOT_PASSWORD = "{{ key "/config/database/root_pass" }}"
           MYSQL_DATABASE = "{{ key "/config/database/name" }}"
           MYSQL_USER = "{{ key "/config/database/user"}}"
           MYSQL_PASSWORD = "{{ key "/config/database/pass"}}"
           }
      resources {
           cpu    = 500
           memory = 256
           }
    }
  }

}
