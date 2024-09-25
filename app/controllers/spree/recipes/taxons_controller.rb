require 'pagy/extras/array'

module Spree
  module Recipes
    class TaxonsController < Spree::StoreController
      include Spree::FrontendHelper
      include Spree::CacheHelper
      helper 'spree/products'

       def index
        @first_recipe = Spree::Recipe.first
        recipe_taxon = Spree::Taxon.find_by_name "Recipes"
        @recipe_taxons = recipe_taxon.children
        recipe_slide_location_names = (1..4).map { |number| "recipe_#{number}" }

        @recipe_slide_locations = Spree::SlideLocation.includes(:slides).where(name: recipe_slide_location_names)
      end

      def show
        @taxon = current_store.taxons.friendly.find("recipes/#{params[:id]}")
        @popular_recipes = @taxon.recipes.where.not(popularity: 0).order(popularity: :desc)

        if params[:q].present?
          recipes = @taxon.recipes.where("name ILIKE ?", "%#{params[:q]}%")
        elsif params[:sort_by].present? && params[:sort_by] == "name-z-a"
          recipes = @taxon.recipes.order(name: :desc)
        else
          recipes = @taxon.recipes.order(name: :asc)
        end

        if browser.device.mobile? || browser.device.tablet?
          @pagy, @recipes = pagy_array(recipes, size: Pagy::DEFAULT[:size_mobile])
        else
          @pagy, @recipes = pagy_array(recipes)
        end
      end

    end
  end
end
