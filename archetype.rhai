let context = #{};

if switch_enabled("debug-answers") {
    log(Info, `${archetect::archetype::description()} Answers:`);
    display(as_yaml(ANSWERS));
}

let org_context = render(Archetype("org-prompts"), ANSWERS);

context += prompt("Project Prefix:", "project-prefix", #{
    cases: [
        CasedIdentityCasedValue(PROGRAMMING_CASES),
    ],
});

let suffix_options = ANSWERS.suffix_options;
let suffix_default = ANSWERS.suffix_default;

if suffix_options != () && type_of(suffix_options) == "array" {
    context += prompt("Project Suffix:", "project-suffix", #{
        defaults_with: suffix_default,
        type: Select(suffix_options),
        cases: [
            CasedIdentityCasedValue(PROGRAMMING_CASES),
        ],
    });
} else {
    context += prompt("Project Suffix:", "project-suffix", #{
        defaults_with: suffix_default,
        cases: [
            CasedIdentityCasedValue(PROGRAMMING_CASES),
        ],
    });
}


context += set("project-name", render("{{project-prefix}}-{{project-suffix}}", context), #{
    cases: [
        CasedIdentityCasedValue(PROGRAMMING_CASES),
        FixedKeyCasedValue("project-title", TitleCase),
    ],
});

// artifact-id: cart-service/artifact_id: cart_service
context += set("artifact-id", context["project-name"], #{
    cases: CasedIdentityCasedValue([KebabCase, SnakeCase]),
    allow_answer: true,
});

let standard = prompt("Project Standard:", #{
    defaults_with: "v2",
    type: Select([
        "v2",
        "v1",
    ]),
    answer_key: "standard",
});

if standard == "v1" {
    context += v1_standard(standard, org_context, context);
} else if standard == "v2" {
    context += v2_standard(standard, org_context, context);
} else {
    log(Error, "Unknown standard: " + standard);
    exit();
}

fn v1_standard(standard, org_context, context) {
    // group-id: p6m.customer.loyalty / group_id: p6m.customer.loyalty
    context += set("group-id", org_context["org-solution-name"], #{
        cases: [
            FixedIdentityCasedValue(PackageCase),
            FixedKeyCasedValue("group_id", PackageCase),
        ],
    });

    // root_package: p6m.customer.loyalty.cart.service
    context += set("root_package", render("{{ group_id }}.{{ artifact_id | package_case }}", org_context + context));

    // root_directory: p6m/p6m/loyalty/cart/service
    context += set("root_directory", render("{{ root_package | directory_case }}", org_context + context));
    context
}

fn v2_standard(standard, org_context, context) {
    // p6m.p6m_loyalty
    context += set("group_id", render("{{ org_name }}.{{ solution_name }}", org_context));
    // p6m.p6m-loyalty
    context += set("group-id", render("{{ org-name }}.{{ solution-name }}", org_context));

    // root_package: p6m.p6m_loyalty.cart_service
    context += set("root_package", render("{{ org_name }}.{{ solution_name }}.{{ artifact_id }}", org_context + context));

    // root_directory: p6m/p6m_loyalty/cart_service
    context += set("root_directory", render("{{ org_name }}/{{ solution_name }}/{{ artifact_id }}", org_context + context));
    context
}

if switch_enabled("debug-context") {
    log(Info, `${archetect::archetype::description()} (${context["project-name"]}) Context:`);
    display(as_yaml(context));
}

// return the context
context
