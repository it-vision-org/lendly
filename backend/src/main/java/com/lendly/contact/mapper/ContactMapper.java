package com.lendly.contact.mapper;

import java.math.BigDecimal;

import org.mapstruct.Mapping;
import org.mapstruct.Mapper;

import com.lendly.contact.api.dto.ContactResponse;
import com.lendly.contact.domain.Contact;

@Mapper(componentModel = "spring")
public interface ContactMapper {

    @Mapping(target = "totalOwedToMe", source = "totalOwedToMe")
    @Mapping(target = "totalIOwe", source = "totalIOwe")
    @Mapping(target = "netBalance", expression = "java(totalOwedToMe.subtract(totalIOwe))")
    ContactResponse toResponse(Contact contact, BigDecimal totalOwedToMe, BigDecimal totalIOwe);
}
