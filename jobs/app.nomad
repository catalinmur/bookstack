job "app" {
 datacenters = ["dc1"]
  
 group "webserver" {

  network {
        mode = "bridge"
        port "http" {
             static = 80
             to = 80
        }
    }
   service {
           name = "bookstack"
           port = "80"
          }
   task "app" {
       driver = "docker"
       config {
              image = "lscr.io/linuxserver/bookstack"
              ports = ["http"]
             }
       env {
            APP_URL = "http://${VAGRANT_IP}"
            DB_HOST = "${VAGRANT_IP}"
            DB_USER = "bookstack"
            DB_PASS = "dbpass"
            DB_DATABASE = "bookstackapp"
         }
       resources {
            cpu    = 500
            memory = 256
         }

    }

 }
}
