rm(list = ls())
setwd("~/workspace/github.com/ChrisLynch96/masters-project/scenario-template/graphs")

library(tidyverse) # collection of packages for every day data science (ggplot2, dplyr, tidyr, readr, purrr, tibble, stringr, forcats)
library(RColorBrewer) # package for choosing sensible colours for plots
library(plotly) # package for making production ready plots (should use this for plotting me thinks)
library(lubridate) # package for data and time
library(caret) # machinelearning
library(tidytext) # Package for conversion of text to
library(spacyr)
library(zoo)
# Chord diagram
library(circlize)
library(gridExtra)
#theme
my_theme <- function(base_size = 12, base_family = "Helvetica"){
  theme(axis.title.y = element_blank(),axis.title.x = element_blank(),
        plot.title = element_text(face="bold", size=16),
        axis.text = element_text(face="bold"),
        plot.background = element_rect(fill = 'snow2',color='white'),
        strip.text.y = element_text(angle=180),
        legend.position = 'None', legend.title = element_blank())
}

## functions and vars

disseminationMethods <- c("pure-ndn_1s", "unsolicited_1s", "proactive_1s", "pure-ndn_100ms", "unsolicited_100ms", "proactive_100ms")

plot_packet_all_total <- function(disseminationMethod, dir) {
  
  data.packets <- read.table(str_c("./data/", disseminationMethod, "/", dir, "/rate-trace.txt"), header=T)
  
  clean_rate_frame(data.packets)
  data.packets = data.packets[c("Time", "Node", "PacketRaw")]
  
  data.packets.nodes = aggregate(PacketRaw ~ Time + Node, data=data.packets, FUN=sum)
  data.packets.total = aggregate(PacketRaw ~ Time, data=data.packets.nodes, FUN=sum)
  
  g.packets.total <- ggplot(data = data.packets.total, aes (x=Time, y=PacketRaw), size=1) +
    geom_line() +
    geom_point() +
    ggtitle(dir) +
    ylab("Packet Numbers") +
    theme_light()
}

plot_packet_all_total2 <- function(dir) {
  data.combined <- combine_methods_packet(dir)
  
  data.combined <- clean_rate_frame(data.combined)
  data.combined = data.combined[c("Time", "Node", "PacketRaw", "method")]
  
  data.combined.nodes = aggregate(PacketRaw ~ Time + Node + method, data=data.combined, FUN=sum)
  data.combined.total = aggregate(PacketRaw ~ Time + method, data=data.combined.nodes, FUN=sum)
  
  g.packets.total <- ggplot(data = data.combined.total, aes (x=Time, y=PacketRaw, group=method, colour=method, shape=method), size=1) +
    geom_line() +
    geom_point() +
    ggtitle(dir) +
    ylab("Packet Numbers") +
    theme_light()
}

plot_speeds_packets <- function(disseminationMethod) {
  directories <- get_directories(disseminationMethod)
  
  i <- 1
  while(i <= 19) {
    speed.frames.list <- list()
    j <- 0
    while(j <= 2) {
      k <- 0
      list_index <- 1
      while(k <= 6) {
        dir <- directories[i+j+k]
        data.packets <- read.table(str_c("./data/", disseminationMethod, "/", dir, "/rate-trace.txt"), header=T)
        data.packets <- clean_rate_frame(data.packets)
        
        components <- str_split(dir, "-")[[1]]
        speed.text <- components[3]
        data.packets <- transform(data.packets, speed = speed.text)
        data.packets = data.packets[c("Time", "Node", "PacketRaw", "speed")]
        data.packets.nodes = aggregate(PacketRaw ~ Time + Node + speed, data=data.packets, FUN=sum)
        data.packets.total = aggregate(PacketRaw ~ Time + speed, data=data.packets.nodes, FUN=sum)
        speed.frames.list[[list_index]] <- data.packets.total
        
        list_index <- list_index + 1
        k <- k + 3
      }
      
      ## appending time
      data.packets.speeds <- speed.frames.list[[1]]
      data.packets.speeds <- rbind(data.packets.speeds, speed.frames.list[[2]])
      data.packets.speeds <- rbind(data.packets.speeds, speed.frames.list[[3]])
      data.packets.speeds$speed <- factor(data.packets.speeds$speed)
      
      ## Format title
      title <- str_c(disseminationMethod, components[1], components[2], components[4], sep = "-")
      
      ## Plotting time
      g.packets.total <- ggplot(data = data.packets.speeds, aes (x=Time, y=PacketRaw, group=speed, colour=speed, shape=speed), size=1) +
        geom_smooth(se=FALSE, method="loess", span=0.1) +
        ggtitle(title) +
        ylab("Packet Numbers") +
        theme_light()
      
      print(g.packets.total)
      
      j <- j + 1
    }
    
    i <- i + 9
  }

}

plot_distance_packets <- function(disseminationMethod) {
  directories <- get_directories(disseminationMethod)
  
  i <- 1
  while(i <= 19) {
    distance.frames.list <- list()
    j <- 0
    while(j <= 2) {
      k <- 0
      list_index <- 1
      while(k <= 2) {
        dir <- directories[i+j+k]
        data.packets <- read.table(str_c("./data/", disseminationMethod, "/", dir, "/rate-trace.txt"), header=T)
        data.packets <- clean_rate_frame(data.packets)
        
        components <- str_split(dir, "-")[[1]]
        distance.text <- components[4]
        data.packets <- transform(data.packets, distance = distance.text)
        data.packets = data.packets[c("Time", "Node", "PacketRaw", "distance")]
        data.packets.nodes = aggregate(PacketRaw ~ Time + Node + distance, data=data.packets, FUN=sum)
        data.packets.total = aggregate(PacketRaw ~ Time + distance, data=data.packets.nodes, FUN=sum)
        distance.frames.list[[list_index]] <- data.packets.total
        
        list_index <- list_index + 1
        k <- k + 1
      }
      
      ## appending time
      data.packets.distance <- distance.frames.list[[1]]
      data.packets.distance <- rbind(data.packets.distance, distance.frames.list[[2]])
      data.packets.distance <- rbind(data.packets.distance, distance.frames.list[[3]])
      data.packets.distance$distance <- factor(data.packets.distance$distance)
      
      ## Format title
      title <- str_c(disseminationMethod, components[1], components[2], components[3], sep = "-")
      
      ## Plotting time
      g.packets.total <- ggplot(data = data.packets.distance, aes (x=Time, y=PacketRaw, group=distance, colour=distance, shape=distance), size=1) +
        geom_smooth(se=FALSE, method="loess", span=0.1) +
        ggtitle(title) +
        ylab("Packet Numbers") +
        theme_light()
      
      print(g.packets.total)
      
      j <- j + 3
    }
    
    i <- i + 9
  }
}

plot_density_packets <- function(disseminationMethod) {
  directories <- get_directories(disseminationMethod)
  
  i <- 1
  while(i <= 9) {
    density.frames.list <- list()
    j <- 0
    while(j <= 2) {
      k <- 0
      list_index <- 1
      while(k <= 18) {
        dir <- directories[i+j+k]
        data.packets <- read.table(str_c("./data/", disseminationMethod, "/", dir, "/rate-trace.txt"), header=T)
        data.packets <- clean_rate_frame(data.packets)
        
        components <- str_split(dir, "-")[[1]]
        density.text <- components[2]
        data.packets <- transform(data.packets, density = density.text)
        data.packets = data.packets[c("Time", "Node", "PacketRaw", "density")]
        data.packets.nodes = aggregate(PacketRaw ~ Time + Node + density, data=data.packets, FUN=sum)
        data.packets.total = aggregate(PacketRaw ~ Time + density, data=data.packets.nodes, FUN=sum)
        density.frames.list[[list_index]] <- data.packets.total
        
        list_index <- list_index + 1
        k <- k + 9
      }
      
      ## appending data frames
      data.packets.density <- density.frames.list[[1]]
      data.packets.density <- rbind(data.packets.density, density.frames.list[[2]])
      data.packets.density <- rbind(data.packets.density, density.frames.list[[3]])
      data.packets.density$density <- factor(data.packets.density$density)
      
      ## Format title
      title <- str_c(disseminationMethod, components[1], components[3], components[4], sep = "-")
      
      ## Plotting time
      g.packets.total <- ggplot(data = data.packets.density, aes (x=Time, y=PacketRaw, group=density, colour=density, shape=density), size=1) +
        geom_smooth(se=FALSE, method="loess", span=0.1) +
        ggtitle(title) +
        ylab("Packet Numbers") +
        theme_light()
      
      print(g.packets.total)
      
      j <- j + 1
    }
    
    i <- i + 3
  }
}

plot_packet_all_box <- function(dir) {
  data.combined <- combine_methods_packet(dir)
  
  data.combined <- clean_rate_frame(data.combined)
  data.combined = data.combined[c("Time", "Node", "PacketRaw", "method")]
  
  data.combined.nodes = aggregate(PacketRaw ~ Time + Node + method, data=data.combined, FUN=sum)
  data.combined.total = aggregate(PacketRaw ~ Time + method, data=data.combined.nodes, FUN=sum)
  
  group.colours <- c("pure-ndn_1s" = "#F88077", "unsolicited_1s" = "#19C034", "proactive_1s" = "#6AA9FF", "pure-ndn_100ms" = "#f5493d", "unsolicited_100ms" = "#0f711f", "proactive_100ms" = "#1a79ff")
  
  g.packets.total.box <- ggplot(data = data.combined.total, aes(x=method, y=PacketRaw, fill=method)) +
    geom_boxplot() +
    ggtitle(dir) +
    xlab("Method") +
    ylab("Packet Numbers") +
    scale_fill_manual(values=group.colours) +
    theme_light() +
    theme(axis.text.x = element_blank())
}

plot_delay_all_total2 <- function(dir) {
  data.delay <- combine_methods_packet(dir, delay = TRUE)
  
  ## Data processing
  data.delay.filtered <- data.delay[c("Time", "Type", "DelayS", "method")]
  data.delay.filtered <- transform(data.delay.filtered, DelayMS = DelayS * 1000)
  
  g.last.delay <- ggplot(data.delay.filtered, aes (x=Time, y=DelayMS, group=method, colour=method, shape=method), size=1) +
    geom_smooth(se=FALSE, method="loess", span=0.1) +
    ggtitle(dir) +
    ylab("Delay (ms)") +
    theme_light()
}

## packets in the network ##
grouped_barcharts_packets <- function(all.packets) {
  
  options(scipen=999)
  
  all.packets.density <- aggregate(PacketRaw ~ method + density, data=all.packets, FUN=sum)
  all.packets.speed <- aggregate(PacketRaw ~ method + speed, data=all.packets, FUN=sum)
  all.packets.range <- aggregate(PacketRaw ~ method + range, data=all.packets, FUN=sum)
  all.packets.all <- aggregate(PacketRaw ~ method, data=all.packets, FUN=sum)
  
  group.colours <- c("pure-ndn_1s" = "#F88077", "unsolicited_1s" = "#19C034", "proactive_1s" = "#6AA9FF", "pure-ndn_100ms" = "#f5493d", "unsolicited_100ms" = "#0f711f", "proactive_100ms" = "#1a79ff")
  
  plot.list <- list()
  
  # Grouped
  plot <- ggplot(all.packets.density, aes(fill=method, y=PacketRaw, x=density)) + 
    geom_bar(position="dodge2", stat="identity") +
    xlab("PCPH") +
    ylab("Packets in the network") +
    ggtitle("Packet Numbers with respect to vehicle density") +
    theme_light() +
    scale_fill_manual(values=group.colours)
  plot.list[[1]] <- plot
  
  plot <- ggplot(all.packets.speed, aes(fill=method, y=PacketRaw, x=speed)) + 
    geom_bar(position="dodge2", stat="identity") +
    xlab("Speed km/h") +
    ylab("Packets in the network") +
    ggtitle("Packet Numbers with respect to vehicle speed") +
    theme_light() +
    scale_fill_manual(values=group.colours)
  plot.list[[2]] <- plot
  
  plot <- ggplot(all.packets.range, aes(fill=method, y=PacketRaw, x=range)) + 
    geom_bar(position="dodge2", stat="identity") +
    xlab("Transmission Range") +
    ylab("Packets in the network") +
    ggtitle("Packet Numbers with respect to transmission range") +
    theme_light() +
    scale_fill_manual(values=group.colours)
  plot.list[[3]] <- plot
  
  plot <- ggplot(all.packets.range, aes(fill=method, y=PacketRaw, x=method)) + 
    geom_bar(stat="identity") +
    xlab("Method") +
    ylab("Packets in the network") +
    ggtitle("Packet Numbers gor each data dissemination method") +
    theme_light() +
    theme(axis.text.x = element_blank()) +
    scale_fill_manual(values=group.colours)
  plot.list[[4]] <- plot
  
  return(plot.list)
}

## Mean delay
grouped_barcharts_delay <- function(all.packets) {
  
  all.packets <- transform(all.packets, DelayMS = DelayS * 1000)
  
  all.packets.density <- aggregate(DelayMS ~ method + density, data=all.packets, FUN=mean)
  all.packets.speed <- aggregate(DelayMS ~ method + speed, data=all.packets, FUN=mean)
  all.packets.range <- aggregate(DelayMS ~ method + range, data=all.packets, FUN=mean)
  all.packets.all <- aggregate(DelayMS ~ method, data=all.packets, FUN=mean)
  
  plot.list <- list()
  
  group.colours <- c("pure-ndn_1s" = "#F88077", "unsolicited_1s" = "#19C034", "proactive_1s" = "#6AA9FF", "pure-ndn_100ms" = "#f5493d", "unsolicited_100ms" = "#0f711f", "proactive_100ms" = "#1a79ff")
  
  # Grouped
  plot <- ggplot(all.packets.density, aes(fill=method, y=DelayMS, x=density)) + 
    geom_bar(position="dodge2", stat="identity") +
    xlab("PCPH") +
    ylab("Mean Delay (ms)") +
    ggtitle("Mean Delay(ms) with respect to traffic density") +
    theme_light() +
    scale_fill_manual(values=group.colours)
  plot.list[[1]] <- plot
  
  plot <- ggplot(all.packets.speed, aes(fill=method, y=DelayMS, x=speed)) + 
    geom_bar(position="dodge2", stat="identity") +
    xlab("Speed km/h") +
    ylab("Mean Delay (ms)") +
    ggtitle("Mean Delay(ms) with respect to vehicle speed") +
    theme_light() +
    scale_fill_manual(values=group.colours)
  plot.list[[2]] <- plot
  
  plot <- ggplot(all.packets.range, aes(fill=method, y=DelayMS, x=range)) + 
    geom_bar(position="dodge2", stat="identity") +
    xlab("Transmission Range") +
    ylab("Mean Delay (ms)") +
    ggtitle("Mean Delay (ms) with respect to transmission range") +
    theme_light() +
    scale_fill_manual(values=group.colours)
  plot.list[[3]] <- plot
  
  plot <- ggplot(all.packets.all, aes(fill=method, y=DelayMS, x=method)) + 
    geom_bar(stat="identity") +
    xlab("Method") +
    ylab("Mean Delay (ms)") +
    ggtitle("Mean Delay(ms) for each data dissemination method") +
    theme_light() +
    theme(axis.text.x = element_blank()) +
    scale_fill_manual(values=group.colours)
  plot.list[[4]] <- plot
  
  return(plot.list)
}

## cache hit ratio ##
grouped_barcharts_cache <- function(cache.frame) {
  ## calculating hit ratios
  
  ### density
  cache.frame.density <- aggregate(cbind(CacheHits, CacheMisses) ~ density + method, data = cache.frame, FUN=sum)
  cache.frame.density <- transform(cache.frame.density, HitRatio = (CacheHits/(CacheHits + CacheMisses)) * 100)
  
  ### speed
  cache.frame.speed <- aggregate(cbind(CacheHits, CacheMisses) ~ speed + method, data = cache.frame, FUN=sum)
  cache.frame.speed <- transform(cache.frame.speed, HitRatio = (CacheHits/(CacheHits + CacheMisses)) * 100)
  
  ### transmission range
  cache.frame.range <- aggregate(cbind(CacheHits, CacheMisses) ~ range + method, data = cache.frame, FUN=sum)
  cache.frame.range <- transform(cache.frame.range, HitRatio = (CacheHits/(CacheHits + CacheMisses)) * 100)
  
  ### all
  cache.frame.all <- aggregate(cbind(CacheHits, CacheMisses) ~ method, data = cache.frame, FUN=sum)
  cache.frame.all <- transform(cache.frame.all, HitRatio = (CacheHits/(CacheHits + CacheMisses)) * 100)
  
  group.colours <- c("pure-ndn_1s" = "#F88077", "unsolicited_1s" = "#19C034", "proactive_1s" = "#6AA9FF", "pure-ndn_100ms" = "#f5493d", "unsolicited_100ms" = "#0f711f", "proactive_100ms" = "#1a79ff")
  
  ## graphing
  plot.list <- list()
  
  ### density
  plot <- ggplot(cache.frame.density, aes(fill=method, y=HitRatio, x=density)) + 
    geom_bar(position="dodge2", stat="identity") +
    xlab("PCPH") +
    ylab("Cache Hit Ratio (%)") +
    ggtitle("Cache Hit ratio with respect to vehicle density") +
    theme_light() +
    scale_fill_manual(values=group.colours)
  plot.list[[1]] <- plot
  
  plot <- ggplot(cache.frame.speed, aes(fill=method, y=HitRatio, x=speed)) + 
    geom_bar(position="dodge2", stat="identity") +
    xlab("Speed km/h") +
    ylab("Cache Hit Ratio (%)") +
    ggtitle("Cache Hit ratio with respect to vehicle speed") +
    theme_light() +
    scale_fill_manual(values=group.colours)
  plot.list[[2]] <- plot
  
  plot <- ggplot(cache.frame.range, aes(fill=method, y=HitRatio, x=range)) + 
    geom_bar(position="dodge2", stat="identity") +
    xlab("Transmission Range") +
    ylab("Cache Hit Ratio (%)") +
    ggtitle("Cache Hit ratio with respect to transmission range") +
    theme_light() +
    scale_fill_manual(values=group.colours)
  plot.list[[3]] <- plot
  
  plot <- ggplot(cache.frame.all, aes(fill=method, y=HitRatio, x=method)) + 
    geom_bar(position="dodge2", stat="identity") +
    xlab("Method") +
    ylab("Cache Hit Ratio (%)") +
    ggtitle("Cache Hit ratio with respect to method") +
    theme_light() +
    theme(axis.text.x = element_blank()) +
    scale_fill_manual(values=group.colours)
  plot.list[[4]] <- plot
  
  return(plot.list)
}


get_directories <- function(disseminationMethod) {
  list.dirs(path = str_c("./data/", disseminationMethod), full.names = FALSE, recursive = FALSE)
}

combine_all_datasets <- function(directories, delay = FALSE, cache = FALSE) {
  packet.totals <- list()
  
  for(i in 1:length(directories)) {
    # need to add information about transmission range and method
    dir <- directories[i]
    dir.combined <- combine_methods_packet(dir, delay = delay, cache = cache)
    components <- str_split(dir, "-")[[1]]
    density <- components[2]
    speed <- components[3]
    tRange <- components[4]
    dir.combined <- transform(dir.combined, density = density)
    dir.combined <- transform(dir.combined, speed = speed)
    dir.combined <- transform(dir.combined, range = tRange)
    
    packet.totals[[i]] <- dir.combined
  }
  
  all.packets <- packet.totals[[1]]
  
  for(i in 2:length(packet.totals)) {
    all.packets <- rbind(all.packets, packet.totals[[i]])
  }
  
  return(all.packets)
}

combine_methods_packet <- function(dir, delay = FALSE, cache = FALSE) {
  
  if (delay) {
    data.ndn <- read.table(str_c("./data/", disseminationMethods[1], "/", dir, "/app-delays-trace.txt"), header=T)
    data.ndn['method'] = 'pure-ndn_1s'
    data.unsolicited <- read.table(str_c("./data/", disseminationMethods[2], "/", dir, "/app-delays-trace.txt"), header=T)
    data.unsolicited['method'] = 'unsolicited_1s'
    data.proactive <- read.table(str_c("./data/", disseminationMethods[3], "/", dir, "/app-delays-trace.txt"), header=T)
    data.proactive['method'] = 'proactive_1s'
    
    data.ndn_100ms <- read.table(str_c("./data/", disseminationMethods[4], "/", dir, "/app-delays-trace.txt"), header=T)
    data.ndn_100ms['method'] = 'pure-ndn_100ms'
    data.unsolicited_100ms <- read.table(str_c("./data/", disseminationMethods[5], "/", dir, "/app-delays-trace.txt"), header=T)
    data.unsolicited_100ms['method'] = 'unsolicited_100ms'
    data.proactive_100ms <- read.table(str_c("./data/", disseminationMethods[6], "/", dir, "/app-delays-trace.txt"), header=T)
    data.proactive_100ms['method'] = 'proactive_100ms'
    
    
    data.combined <- rbind(data.ndn, data.unsolicited)
    data.combined <- rbind(data.combined, data.proactive)
    data.combined <- rbind(data.combined, data.ndn_100ms)
    data.combined <- rbind(data.combined, data.unsolicited_100ms)
    data.combined <- rbind(data.combined, data.proactive_100ms)
    data.combined$method <- factor(data.combined$method)
    
    return(data.combined)
  } else if (cache) {
    data.ndn <- read.table(str_c("./data/", disseminationMethods[1], "/", dir, "/cs-trace.txt"), header=T)
    data.ndn['method'] = 'pure-ndn_1s'
    data.unsolicited <- read.table(str_c("./data/", disseminationMethods[2], "/", dir, "/cs-trace.txt"), header=T)
    data.unsolicited['method'] = 'unsolicited_1s'
    data.proactive <- read.table(str_c("./data/", disseminationMethods[3], "/", dir, "/cs-trace.txt"), header=T)
    data.proactive['method'] = 'proactive_1s'
    
    data.ndn_100ms <- read.table(str_c("./data/", disseminationMethods[4], "/", dir, "/cs-trace.txt"), header=T)
    data.ndn_100ms['method'] = 'pure-ndn_100ms'
    data.unsolicited_100ms <- read.table(str_c("./data/", disseminationMethods[5], "/", dir, "/cs-trace.txt"), header=T)
    data.unsolicited_100ms['method'] = 'unsolicited_100ms'
    data.proactive_100ms <- read.table(str_c("./data/", disseminationMethods[6], "/", dir, "/cs-trace.txt"), header=T)
    data.proactive_100ms['method'] = 'proactive_100ms'
    
    data.combined <- rbind(data.ndn, data.unsolicited)
    data.combined <- rbind(data.combined, data.proactive)
    data.combined <- rbind(data.combined, data.ndn_100ms)
    data.combined <- rbind(data.combined, data.unsolicited_100ms)
    data.combined <- rbind(data.combined, data.proactive_100ms)
    data.combined$method <- factor(data.combined$method)
    
    return(data.combined)
  }
  else {
    data.ndn <- read.table(str_c("./data/", disseminationMethods[1], "/", dir, "/rate-trace.txt"), header=T)
    data.ndn['method'] = 'pure-ndn_1s'
    data.unsolicited <- read.table(str_c("./data/", disseminationMethods[2], "/", dir, "/rate-trace.txt"), header=T)
    data.unsolicited['method'] = 'unsolicited_1s'
    data.proactive <- read.table(str_c("./data/", disseminationMethods[3], "/", dir, "/rate-trace.txt"), header=T)
    data.proactive['method'] = 'proactive_1s'
    
    data.ndn_100ms <- read.table(str_c("./data/", disseminationMethods[4], "/", dir, "/rate-trace.txt"), header=T)
    data.ndn_100ms['method'] = 'pure-ndn_100ms'
    data.unsolicited_100ms <- read.table(str_c("./data/", disseminationMethods[5], "/", dir, "/rate-trace.txt"), header=T)
    data.unsolicited_100ms['method'] = 'unsolicited_100ms'
    data.proactive_100ms <- read.table(str_c("./data/", disseminationMethods[6], "/", dir, "/rate-trace.txt"), header=T)
    data.proactive_100ms['method'] = 'proactive_100ms'
    
    data.combined <- rbind(data.ndn, data.unsolicited)
    data.combined <- rbind(data.combined, data.proactive)
    data.combined <- rbind(data.combined, data.ndn_100ms)
    data.combined <- rbind(data.combined, data.unsolicited_100ms)
    data.combined <- rbind(data.combined, data.proactive_100ms)
    data.combined$method <- factor(data.combined$method)
    
    data.combined <- clean_rate_frame(data.combined)
    
    return(data.combined)
  }
}

clean_rate_frame <- function(data.packets) {
  data.packets$Node = factor(data.packets$Node)
  data.packets$FaceDescr = factor(data.packets$FaceDescr)
  data.packets$Type = factor(data.packets$Type)
  data.packets <- data.packets[!data.packets$FaceDescr == "all",]
  data.packets <- data.packets[!data.packets$FaceDescr == "internal://",]
  data.packets <- data.packets[!data.packets$FaceDescr == "appFace://",]
  data.packets <- data.packets[!data.packets$Type == "InNacks",]
  data.packets <- data.packets[!data.packets$Type == "OutNacks",]
}

convert_vehicles_to_percentages <- function(density) {
  density <- as.character(density)
  density[density == '285v'] <- '15%'
  density[density == '950v'] <- '50%'
  density[density == '1900v'] <- '100%'
  density <- as.factor(density)
}

correct_order_of_factors <- function(data.frame) {
  data.frame$method <- factor(data.frame$method, levels=c("pure-ndn_1s", "pure-ndn_100ms", "unsolicited_1s", "unsolicited_100ms", "proactive_1s", "proactive_100ms"))
  data.frame$density <- factor(data.frame$density, levels=c("15%", "50%", "100%"))
  data.frame$speed <- factor(data.frame$speed, levels=c("30kmh", "60kmh", "100kmh"))
  
  return(data.frame)
}

subset_by_time <- function(data.frame, time) {
  data.frame <- data.frame[which(data.frame$Time > time),]
}

convert_to_tidy_cache_format <- function(untidy.frame) {
  cache.hits <- untidy.frame[untidy.frame$Type == "CacheHits",]
  cache.hits <- transform(cache.hits, CacheHits = Packets)
  cache.misses <- untidy.frame[untidy.frame$Type == "CacheMisses",]
  cache.misses <- transform(cache.misses, CacheMisses = Packets)
  
  cache.frame <- cbind(cache.hits, CacheMisses = cache.misses$CacheMisses)
  cache.frame <- cache.frame[c("Time", "Node", "density", "speed", "range", "CacheHits", "CacheMisses", "method")]
}

plot_cache_over_time <- function(dir, node1, node2) {
  data.ndn <- read.table(str_c("./data/misc/", dir, "/cs-trace.txt"), header=T)
  
  components <- str_split(dir, "-")[[1]]
  method <- "pure-ndn"
  density <- components[2]
  speed <- components[3]
  tRange <- components[4]
  data.ndn <- transform(data.ndn, method = method)
  data.ndn <- transform(data.ndn, density = density)
  data.ndn <- transform(data.ndn, speed = speed)
  data.ndn <- transform(data.ndn, range = tRange)
  
  data.ndn <- convert_to_tidy_cache_format(data.ndn)
  
  ## get the just the node IDs that I'm interested in
  data.ndn <- subset(data.ndn, Node == '5' | Node == '46')
  data.ndn$Node <- as.factor(data.ndn$Node)
  
  plot <- ggplot(data.ndn, aes(x=Time, y=CacheHits, group=Node, colour=Node))  + 
    geom_line() +
    xlab("Time") +
    ylab("Cache Hits") +
    theme_light()
}

## MAIN ##

#setting up data.frames

directories <- get_directories(disseminationMethods[1])
all.packets <- combine_all_datasets(directories)
all.delay <- combine_all_datasets(directories, delay = TRUE)
all.cache <- combine_all_datasets(directories, cache = TRUE)

all.packets <- subset_by_time(all.packets, 20)
all.delay <- subset_by_time(all.delay, 20)
all.cache <- subset_by_time(all.cache, 20)

all.packets$density <- convert_vehicles_to_percentages(all.packets$density)
all.delay$density <- convert_vehicles_to_percentages(all.delay$density)
all.cache$density <- convert_vehicles_to_percentages(all.cache$density)

all.packets <- correct_order_of_factors(all.packets)
all.delay <- correct_order_of_factors(all.delay)
all.cache <- correct_order_of_factors(all.cache)

all.cache <- convert_to_tidy_cache_format(all.cache)

all.packets.1s <- subset(all.packets, method == 'pure-ndn_1s' | method == 'unsolicited_1s' | method == 'proactive_1s')
all.delay.1s <- subset(all.delay, method == 'pure-ndn_1s' | method == 'unsolicited_1s' | method == 'proactive_1s')
all.cache.1s <- subset(all.cache, method == 'pure-ndn_1s' | method == 'unsolicited_1s' | method == 'proactive_1s')

all.packets.100ms <- subset(all.packets, method == 'pure-ndn_100ms' | method == 'unsolicited_100ms' | method == 'proactive_100ms')
all.delay.100ms <- subset(all.delay, method == 'pure-ndn_100ms' | method == 'unsolicited_100ms' | method == 'proactive_100ms')
all.cache.100ms <- subset(all.cache, method == 'pure-ndn_100ms' | method == 'unsolicited_100ms' | method == 'proactive_100ms')

pdf("plots-all2.pdf")

## Packet Number bar charts
plot.list <- grouped_barcharts_packets(all.packets)

for(i in 1:length(plot.list)) {
  print(plot.list[[i]])
}

## delay bar charts
plot.list <- grouped_barcharts_delay(all.delay)

for(i in 1:length(plot.list)) {
  print(plot.list[[i]])
}

## cache hit ratio bar charts
plot.list <- grouped_barcharts_cache(all.cache)

for(i in 1:length(plot.list)) {
  print(plot.list[[i]])
}

dev.off()

pdf("congestion-boxplots.pdf")
## packet numbers vs method
for (i in 1:length(directories)) {
  dir <- directories[i]
  fig <- plot_packet_all_box(dir)
  print(fig)
}
dev.off()


## Delay vs method
for(i in 1:length(directories)) {
  dir <- directories[i]
  fig <- plot_delay_all_total2(dir)
  print(fig)
}

## speed
for(method in disseminationMethods) {
  plot_speeds_packets(method)
}

## density
for(method in disseminationMethods) {
  plot_density_packets(method)
}

## distance
for(method in disseminationMethods) {
  plot_distance_packets(method)
}
