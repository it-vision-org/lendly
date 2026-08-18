package com.lendly.transaction.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import com.lendly.transaction.api.dto.RepaymentResponse;
import com.lendly.transaction.api.dto.TransactionResponse;
import com.lendly.transaction.domain.Repayment;
import com.lendly.transaction.domain.Transaction;

@Mapper(componentModel = "spring")
public interface TransactionMapper {

    @Mapping(target = "contactId", source = "contact.id")
    @Mapping(target = "contactName", source = "contact.name")
    TransactionResponse toResponse(Transaction transaction);

    @Mapping(target = "transactionId", source = "transaction.id")
    RepaymentResponse toResponse(Repayment repayment);
}
