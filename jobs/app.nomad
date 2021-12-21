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
            APP_URL = "http://192.168.56.210"
            DB_HOST = "192.168.56.210"
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
