The error "Unknown column 'site_experiences.tourist_site_id' in 'WHERE'" indicates a database schema mismatch in your Laravel backend. The `site_experiences` table is likely designed with a polymorphic relationship (using `experiencable_id` and `experiencable_type`) rather than a direct `tourist_site_id` foreign key.

To fix this, you need to:

1.  **Verify `site_experiences` table migration:** Ensure it uses `$table->morphs('experiencable');`.
2.  **Update `app/Models/TouristSite.php`:** Add a `morphMany` relationship:
    ```php
    use App\Models\SiteExperience;

    public function experiences()
    {
        return $this->morphMany(SiteExperience::class, 'experiencable');
    }
    ```
3.  **Update `app/Models/SiteExperience.php`:** Add a `morphTo` relationship:
    ```php
    public function experiencable()
    {
        return $this->morphTo();
    }
    ```
4.  **Update `app/Http/Controllers/Api/TouristSiteController.php`:** Modify the `experiences` method:
    ```php
    use App\Http\Resources\SiteExperienceResource;

    public function experiences(TouristSite $touristSite)
    {
        $experiences = $touristSite->experiences()
                                   ->with('user.profile')
                                   ->orderBy('created_at', 'desc')
                                   ->paginate(10);
        return SiteExperienceResource::collection($experiences);
    }
    ```
Please apply these changes to your Laravel backend.
