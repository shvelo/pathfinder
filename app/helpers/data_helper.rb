module DataHelper
  def render_data_menu(main_object, tabs)
    current_tab = params[:tab] || 'main'
    menu_data = [{ label: 'ზოგადი', tab: 'main', url: tab_url(main_object, 'main') }]
    tabs.each do |tab|
      cnt = main_object.send(tab.to_sym).count
      menu_data.append({ label: tab_label(tab), tab: tab, url: tab_url(main_object, tab), count: cnt })
    end
    render partial: '/data/menu', locals: { menu_data: menu_data, current_tab: current_tab }
  end

  def render_data(main_object)
    current_tab = params[:tab] || 'main'
    if current_tab == 'main'
      class_name = main_object.class.name.downcase.pluralize
      render partial: "/#{class_name}/main", locals: { data: main_object }
    else
      subobject_render(main_object, current_tab)
    end
  end

  private

  def tab_url(main_object, tab)
    if main_object.is_a?(Region)
      region_url(main_object, tab: tab)
    end
  end

  def tab_label(tab)
    case tab
    when 'offices' then 'ოფისები'
    when 'substations' then 'ქვესადგურები'
    when 'towers' then 'ანძები'
    when 'lines' then  'ხაზები'
    when 'tps' then 'სატრ.ჯიხურები'
    when 'poles' then 'ბოძები'
    when 'fiders' then 'ფიდერები'
    else tab
    end
  end

  def subobject_render(main_object, tab)
    data = main_object.send(tab.to_sym)
    case tab
    when 'substations'
      render partial: '/objects/substations/table', data: main_object.substations
    else
      render partial: '/data/no_template'
    end
  end
end
