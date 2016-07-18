require 'net/http'
require 'json'
require 'ostruct'

module Subject
  def initialize
    @observers = []
  end

  def registerObserver(observer)
    @observers << observer
  end

  def removeObserver(observer)
    @observers.delete observer
  end

  def notifyObservers
    @observers.each do |observer|
      observer.update(self.temp, self.humidity, self.pressure)
    end
  end
end

module Observer
  def update(temp, humidity, pressure)
    raise NotImplementedError, 'Implement this method!'
  end
end

module DisplayElement
  def display
    raise NotImplementedError, 'Implement this method!'
  end
end

class WeatherData
  include Subject
  attr_accessor :temp, :humidity, :pressure

  def measurements_changed
    notifyObservers
  end

  def setMeasurements(temp=nil, humidity=nil, pressure=nil)
    url = 'https://query.yahooapis.com/v1/public/yql?q=select%20item.forecast%2C%20item.condition%2C%20atmosphere%20%20%20from%20weather.forecast%20where%20woeid%20%3D%202306179%20and%20u%3D%22c%22%20limit%201&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys'
    uri = URI(url)
    response = Net::HTTP.get(uri)
    obj = JSON.parse(response, object_class: OpenStruct)

    self.temp     = ( temp != nil ) ? temp : obj.query.results.channel.item.condition.temp
    self.humidity = ( humidity != nil ) ? humidity : obj.query.results.channel.atmosphere.humidity
    self.pressure = ( pressure != nil ) ? pressure : obj.query.results.channel.atmosphere.pressure
    measurements_changed()
  end

end

class CurrentConditionsDisplay
  include Observer, DisplayElement
  attr_accessor :temp, :humidity, :pressure, :subject

  def initialize(weatherData)
    self.subject = weatherData
    self.subject.registerObserver(self)
  end

  def update(temp, humidity, pressure)
    self.temp     = temp
    self.humidity = humidity
    self.pressure = pressure
    display
  end

  def display
    puts "目前情況 : 溫度 = #{temp}度C, 濕度 = #{humidity}%, 壓力 = #{pressure}"
  end
end

class WeatherStation
  def initialize
    puts 'WeatherStation Start'
    w = WeatherData.new
    c = CurrentConditionsDisplay.new(w)
    w.setMeasurements
    w.setMeasurements 100, 100, 100
  end
end


w = WeatherStation.new
