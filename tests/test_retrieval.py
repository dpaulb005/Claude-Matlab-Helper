from bridge.retrieval import build_notes_context, extract_terms, score_chunk


def test_extract_terms_drops_stopwords_and_short_words():
    terms = extract_terms("What is the Fourier transform of this signal in the notes?")

    assert "what" not in terms
    assert "the" not in terms
    assert "fourier" in terms
    assert "signal" in terms


def test_score_chunk_boosts_signals_relevance():
    text = "This lecture covers sampling, aliasing, Nyquist rate, and spectral replicas."
    score = score_chunk(text, ["sampling", "aliasing"])

    assert score >= 4


def test_build_notes_context_prefers_relevant_chunks():
    manifest = {
        "documents": [
            {
                "title": "Lecture 1",
                "chunks": [
                    {"page": 2, "text": "Sampling and aliasing examples with Nyquist discussion."},
                    {"page": 7, "text": "Unrelated administrative notes about office hours."},
                ],
            }
        ]
    }

    context = build_notes_context("Explain aliasing in sampling", manifest=manifest)

    assert "Sampling and aliasing examples" in context
    assert "office hours" not in context
