package com.lendly;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class LendlyApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(LendlyApiApplication.class, args);
	}

}
