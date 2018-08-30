local context = {{ context }};
local prefix =  "ocds-xxxxx-";

local safeGet = function(obj, name) if name in obj then obj[name];

local identifier(ident) = {
      scheme: ident.scheme,
      id: ident.id,
      legalName: ident.legalName,
      uri: if std.objectHas(ident, 'uri') then ident.uri,
};
local organizationRef(ref) = {
      id: "UA-EDR" + ref.identifier.id,
      name: ref.name
};
local period(period) = {
      startDate: period.startDate,
      endDate: period.endDate
};
local address(obj) = {
      region: obj.region,
      postalCode: obj.postalCode
};
local contactPoint(obj) = {
      name: if std.objectHas(obj, 'name') then obj.name,
      email: if std.objectHas(obj, 'email') then obj.email,
      telephone: if std.objectHas(obj, 'telephone') then obj.telephone,
      faxNumber:  if std.objectHas(obj, 'faxNumber') then obj.faxNumber,
      url: if std.objectHas(obj, 'url') then obj.url
};
local value(obj) = {
      amount: obj.amount,
      currency: obj.currency
};
local classification(obj) = {
      scheme: obj.scheme,
      id: obj.id,
      description: obj.description,
      uri: safeGet(obj, 'uri')
};
local item(item) = {
      id: item.id,
      description: item.description,
      quantity: item.quantity,
      classification: classification(item.classification),
      additionalClassifications: [classification(cls) for cls in safeGet(item, 'additionalClassifications')],
      unit: {
	    id: item.unit.code,
	    name: item.unit.name
      }
};
local document(doc) = {
      id: doc.id,
      documentType: if 'documentType' in doc then doc.documentType,
      title: doc.title,
      description: if 'description' in doc then doc.description,
      url: doc.url,
      datePublished: doc.datePublished,
      dateModified: doc.dateModified,
      format: doc.format,
      language: if 'language' in doc then doc.language
};
local party(item) = {
      id: "UA-EDR-" + item.identifier.id,
      name: item.name,
      identifier: identifier(item.identifier),
      additionalIdentifiers: if std.objectHas(item, 'additionalIdentifiers') then [identifier(i) for i in item.additionalIdentifiers],
      address: address(item.address),
      contactPoint: contactPoint(item),
      roles: ['tender']
};
local awardMap(award) = {
      id: award.id,
      title: if 'title' in award then award.title,
      description: if 'description' in award then award.description,
      status: award.status,
      date: award.date,
      value: value(award.value),
      suppliers: [organizationRef(supp) for supp in award.suppliers],
      items: if 'items' in award then [item(i) for i in award.items],
      contractPeriod: if 'contractPeriod' in award then period(award.contractPeriod),
      documents: if 'documens' in award then [document(doc) for doc in award.documents],
};
local contractMap(contract) = {
      id: contract.id,
      title: if 'title' in contract then contract.title,
      awardID: contract.awardID,
      period: period(contract.period),
      description: if 'description' in contract then contract.description,
      status: contract.status,
      date: contract.date,
      value: value(contract.value),
      items: [item(i) for i in contract.items],
      dateSigned: contract.dateSigned,
      documents: [document(doc) for doc in contract.documensx]
};
local tenderMap(tender) = {
      id: tender._id,
      title: tender.title,
      description: tender.description,
      status: std.split(tender.status, '.')[0],
      procuringEntity: organizationRef(tender.procuringEntity),
      items: [item(i) for i in context.items],
      value: value(tender.value),
      procurementMethod: tender.procurementMethod,
      procurementMethodDetails: tender.procurementMethodDetails,
      awardCriteria: tender.awardCriteria,
      awardCriteriaDetails: if std.objectHas(tender, 'awardCriteriaDetails') then tender.awardCriteriaDetails,
      submissionMethod: tender.submissionMethod,
      submissionMethodDetails: if std.objectHas(tender, 'submissionMethodDetails') then tender.submissionMethodDetails,
      tenderPeriod: period(tender.tenderPeriod),
      enquiryPeriod: period(tender.enquiryPeriod),
      eligibilityCriteria: if 'eligibilityCriteria' in tender then tender.eligibilityCriteria,
      tenderers: std.flattenArrays([[organizationRef(t) for t in bid['tenderers']] for bid in tender.bids]),
      numberOfTenderers: std.length(self.tenderers),
      documents: [document(doc) for doc in tender.documents]
};

{
  ocid: prefix + context.tenderID,
  id: context._id,
  date: context.dateModified,
  initiationType: "tender",
  parties: std.map(party, std.flattenArrays(
  	   [bid['tenderers'] for bid in context.bids if std.objectHas(context, 'bids')] +
	   [award.suppliers for award in context.awards if std.objectHas(context, 'awards')]
  	   ) + [context.procuringEntity]),
  buyer: context.procuringEntity,
  awards: if std.objectHas(context, 'awards') then [awardMap(award) for award in context.awards],
  contracts: if std.objectHas(context, 'contracts') then [contractMap(contract) for contract in context.contracts],
  tender: tenderMap(context)
}
