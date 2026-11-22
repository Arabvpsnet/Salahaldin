<?php

namespace Tests\Feature;

use Tests\TestCase;

class ExampleTest extends TestCase
{
    /** Canonical readonly Salahaldin API is available without an installation redirect. */
    public function test_read_only_quran_edition_catalog_is_available(): void
    {
        $this->get('/api/salahaldin/v1/quran/editions')->assertOk();
    }
}
