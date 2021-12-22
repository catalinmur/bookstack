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
            APP_URL = "http://{{ key "/config/vagrant_ip" }}"
            DB_HOST = "{{ key "/config/vagrant_ip" }}"
            DB_USER = "{{ key "/config/database/user" }}"
            DB_PASS = "{{ key "/config/database/pass" }}"
            DB_DATABASE = "{{ key "/config/database/name" }}"
         }
       resources {
            cpu    = 500
            memory = 256
         }

    }

 }
}
