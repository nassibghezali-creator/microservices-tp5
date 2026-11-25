package com.example.orderservice;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;

// "demo" = spring.application.name du service demo (résolu via Eureka)
@FeignClient(name = "demo")
public interface DemoFeignClient {

    @GetMapping("/hello")
    String callHello();
}
