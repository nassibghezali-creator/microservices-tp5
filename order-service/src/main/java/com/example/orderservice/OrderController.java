package com.example.orderservice;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class OrderController {

    @Autowired
    private DemoFeignClient demoFeignClient;

    @GetMapping("/order")
    @CircuitBreaker(name = "demoService", fallbackMethod = "fallbackOrder")
    public String createOrder() {
        String response = demoFeignClient.callHello();
        return "Commande créée. Réponse du service demo : " + response;
    }

    // Fallback : même signature que la méthode d'origine + Throwable en dernier paramètre
    public String fallbackOrder(Throwable t) {
        return "Service demo indisponible. Commande enregistrée en mode dégradé. Cause : "
                + t.getClass().getSimpleName() + " - " + t.getMessage();
    }
}
