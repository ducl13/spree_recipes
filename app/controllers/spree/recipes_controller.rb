module Spree
  class RecipesController < Spree::StoreController
    include Spree::FrontendHelper
    include Spree::CacheHelper
    helper 'spree/products'

    def show
      @recipe = Spree::Recipe.friendly.find(params[:id])
      @taxon = params[:taxon_id].present? ? Spree::Taxon.find_by_id(params[:taxon_id]) : @recipe&.taxons&.first
      @related_recipes = Rails.cache.fetch("@related_recipes", expires_in: Rails.configuration.x.cache.expiration, race_condition_ttl: 30.seconds) do 
        @taxon.recipes.where.not(id: @recipe.id).first(4)
      end
    end

    def display_products_modal
      @recipe = Spree::Recipe.friendly.find(params[:id])
      @recipe_products = @recipe.ingredients.joins(:product).map { |ingredient| ingredient.product }
    end

    def generate_pdf
      @recipe = Spree::Recipe.friendly.find(params[:id])
      file_name = @recipe.name.parameterize
      respond_to do |format|
        format.pdf do
          render pdf: file_name,
                 template: 'spree/recipes/generate_pdf.html.erb',
                 layout: 'spree/layouts/pdf.html.erb'
        end
      end
    end

    def add_to_cart
      variant = Spree::Variant.find_by(id:params[:id])
      quantity = params[:quantity] || 1
      @order = current_order || Order.incomplete.find_by(token: cookies.signed[:token]) || current_order(create_order_if_necessary: true)
      line_item = Spree::Dependencies.cart_add_item_service.constantize.call(order: @order, variant: variant,quantity: quantity, options: {}).value

      if line_item.save
        @success_messages = "#{variant.name} successfully added to cart"
        flash[:success] = @messages
      else
        @error_messages = line_item.errors.full_messages.join(",")
        flash[:error] = @messages
      end
      respond_to do |format|
        format.html { redirect_to request.referer }
        format.js
      end
    end

  end
end
