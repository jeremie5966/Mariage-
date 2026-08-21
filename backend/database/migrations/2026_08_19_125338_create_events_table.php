<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('events', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('bride_name');
            $table->string('groom_name');
            $table->dateTime('event_date');
            $table->string('venue');
            $table->string('address')->nullable();
            $table->text('invitation_message')->nullable();
            $table->string('primary_color')->default('#B58B5A');
            $table->string('secondary_color')->default('#F7F1E8');
            $table->string('logo')->nullable();
            $table->string('status')->default('active')->index();
            $table->boolean('single_use')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('events');
    }
};
