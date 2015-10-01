var dc = new rdf.Namespace(
	"http://purl.org/dc/elements/1.1/",
	["title", "coverage", "date", "identifier", "format", "type", "creator", "subject", "rights", "contributor", "publisher", "language", "source", "description", "relation"]);
var dcterms = new rdf.Namespace(
	"http://purl.org/dc/terms/",
	["relation", "date", "hasVersion", "conformsTo", "description", "audience", "source", "instructionalMethod", "dateCopyrighted", "accessRights", "dateAccepted", "isRequiredBy", "valid", "subject", "issued", "accrualMethod", "temporal", "extent", "replaces", "coverage", "language", "title", "spatial", "tableOfContents", "hasPart", "isReplacedBy", "hasFormat", "isFormatOf", "publisher", "provenance", "identifier", "accrualPeriodicity", "contributor", "isVersionOf", "rights", "requires", "format", "abstract", "medium", "alternative", "creator", "type", "isReferencedBy", "references", "educationLevel", "modified", "license", "rightsHolder", "accrualPolicy", "created", "isPartOf", "bibliographicCitation", "dateSubmitted", "available", "mediator"]);
var foaf = new rdf.Namespace(
	"http://xmlns.com/foaf/0.1/",
	["based_near", "openid", "aimChatID", "img", "icqChatID", "gender", "familyName", "mbox", "page", "age", "dnaChecksum", "accountServiceHomepage", "accountName", "topic_interest", "myersBriggs", "currentProject", "phone", "depiction", "lastName", "homepage", "thumbnail", "isPrimaryTopicOf", "mbox_sha1sum", "workInfoHomepage", "skypeID", "weblog", "interest", "status", "title", "name", "holdsAccount", "knows", "publications", "primaryTopic", "workplaceHomepage", "plan", "family_name", "pastProject", "yahooChatID", "member", "tipjar", "account", "focus", "surname", "maker", "givenName", "schoolHomepage", "topic", "made", "logo", "depicts", "theme", "fundedBy", "geekcode", "sha1", "firstName", "jabberID", "birthday", "givenname", "nick", "msnChatID", "membershipClass"]);
var owl = new rdf.Namespace(
	"http://www.w3.org/2002/07/owl#",
	["minCardinality", "differentFrom", "distinctMembers", "hasValue", "disjointWith", "equivalentProperty", "priorVersion", "equivalentClass", "inverseOf", "cardinality", "incompatibleWith", "oneOf", "complementOf", "backwardCompatibleWith", "intersectionOf", "versionInfo", "onProperty", "someValuesFrom", "maxCardinality", "unionOf", "allValuesFrom", "imports", "sameAs"]);
var rdf = new rdf.Namespace(
	"http://www.w3.org/1999/02/22-rdf-syntax-ns#",
	["first", "subject", "object", "rest", "value", "type", "predicate"]);
var rdfs = new rdf.Namespace(
	"http://www.w3.org/2000/01/rdf-schema#",
	["isDefinedBy", "label", "member", "comment", "subClassOf", "domain", "subPropertyOf", "seeAlso", "range"]);
var skos = new rdf.Namespace(
	"http://www.w3.org/2004/02/skos/core#",
	["hiddenLabel", "hasTopConcept", "altLabel", "broadMatch", "narrower", "editorialNote", "notation", "note", "example", "topConceptOf", "relatedMatch", "definition", "mappingRelation", "inScheme", "historyNote", "semanticRelation", "broader", "narrowerTransitive", "exactMatch", "narrowMatch", "related", "changeNote", "member", "prefLabel", "broaderTransitive", "closeMatch", "memberList", "scopeNote"]);
