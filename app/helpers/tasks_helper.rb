# -*- encoding : utf-8 -*-
module TasksHelper
  def tasks_table(tasks, opts={})
    table_for tasks, title: opts[:title]||'დავალებები', icon: '/icons/report-paper.png', collapsible: true do |t|
      t.text_field :number, tag: 'code'
      t.text_field 'status_name', i18n: 'status', icon: ->(x){ x.status_icon }
      t.text_field :note
      t.complex_field i18n: 'assignee' do |t|
        t.text_field 'assignee.username', tag: 'strong'
        t.text_field 'assignee.full_name'
      end
      t.paginate records: 'ჩანაწერი'
    end
  end
end