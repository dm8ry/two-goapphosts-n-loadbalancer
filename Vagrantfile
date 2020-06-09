ENV['VAGRANT_NO_PARALLEL'] = 'true'

Vagrant.configure("2") do |config|

MACHINE = ["none.host", "app1.host","app2.host"]
N = 2

  (1..N).each do |i|
  config.vm.define "app#{i}" do |app|
    app.vm.provider "docker" do |d|
    app.vm.hostname = MACHINE[i]
      d.build_dir = "./app"
      d.name = "app#{i}"
      d.expose = ['8080']
    end
  end
  end

  config.vm.define "loadbalancer" do |lb|
    lb.vm.provider "docker" do |d|
    lb.vm.hostname = "loadbalancer.host"
      d.build_dir = "./lb"
      d.name = "loadbalancer"
      d.link("app1:app1")
      d.link("app2:app2")
    end
  end


end
