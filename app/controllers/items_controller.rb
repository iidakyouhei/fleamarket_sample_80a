class ItemsController < ApplicationController
  before_action :set_category, only:[:create]
  before_action :move_to_index_destroy, only: [:destroy]
  before_action :set_item_search_query
  def index
    @items = Item.includes(:item_images).order('created_at DESC').limit(5)
  end

  def new
    @item = Item.new
    @item_image = @item.item_images.build
    @parents = Category.where(ancestry: nil)
    respond_to do |format|
      format.html
      format.json do
        #親ボックスのidから子ボックスのidの配列を作成してインスタンス変数で定義
        if params[:parent_id].present?
          @children = Category.find(params[:parent_id]).children
        #子ボックスのidから孫ボックスのidの配列を作成してインスタンス変数で定義
        elsif params[:child_id].present?
          @grandchildren = Category.find(params[:child_id]).children
        end
      end
    end
  end
  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to root_path
    else  
    @item.valid?
    # flash.now[:alert] = @item.errors.full_messages
    render :new and return
    end
  end

  def show
    @item = Item.find(params[:id])
    @user = User.find(@item.user_id)
    #find_byでitemがあるかないかあったら@purchaseにいれる
    @purchase = Purchase.find_by(item_id: @item.id)
    @category_id = @item.category_id
    @category = Category.find(@category_id)
  end

  def done
  end

  def update
    if @item.update(item_params)
      redirect_to root_path
    else  
      render :edit
    end
  end

  def destroy

    if @item.destroy
       redirect_to root_path
    else
      render :edit
    end
  end

  def search
    @items = Item.search(params[:keyword])

    @q = Item.includes(:images).search(search_items_path)
    sort = params[:sort] || "created_at DESC"    
    # jsから飛んできたパラーメーターが"likes_count_desc"の場合に、子モデルの多い順にソートする記述を  
    if sort == "likes_count_desc"
      @items = @q.result(distinct: true).select('items.*', 'count(likes.id) AS likes')
        .left_joins(:likes)
        .group('items.id')
        .order('likes DESC').order('created_at DESC')
    else
    end
  end


  private

  def item_params
    params.require(:item).permit(:name, :description, :price, :category_id,:brand_name, :condition_id, :shipping_cost_id, :area_id, :day_id, item_images_attributes: [:image, :_destroy, :id]).merge(user_id: current_user.id)
  end


  def set_category
    @parents = Category.where(ancestry: nil)
  end

  def move_to_index_destroy
    @item = Item.find(params[:id])
    redirect_to root_path unless current_user.id == @item.user_id
  end

end
