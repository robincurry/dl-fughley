require 'rubygems'
require 'activerecord'
require 'action_mailer'

module DL
  module Fughley
    def self.included(base)
      base.extend(IsDL)
    end

    module IsDL
      def is_dl(*args)
        options = args.extract_options!
        (class << self; self; end).instance_eval do
          dl_name = options[:as] || args.first
          method_name = ("dl_" + dl_name.to_s).to_sym
          send :define_method, method_name do
            [self.send(dl_name), options || {}]
          end
        end

        extend ClassMethods unless (class << self; included_modules; end).include?(ClassMethods)
      end
    end

    module ClassMethods
      def dl(name)
        method_name = ("dl_" + name.to_s).to_sym
        if self.respond_to?(method_name)
          self.send(method_name)
        elsif self.respond_to?(:dl_missing)
          self.send(:dl_missing, name)
        else
          []
        end
      end

      def distribute(email)
        to = email.to.first
        list = to.gsub(/@.*$/, '')


        people = dl(list)
        options = {
          :allow => [],
          :email_field => :email,
          :reply_to => :sender
          }.merge!(people.extract_options!)
          
          people.flatten!

          if (options[:allow].nil? || options[:allow].empty?) || 
            options[:allow].include?(email.from.first) || 
            (options[:allow].include?(:members) && people.detect{|p| p.email == email.from.first})

            people.each do |person|
              email.to = person.send(options[:email_field])
              email.reply_to = email.from if options[:reply_to] == :sender
              email.reply_to = to if options[:reply_to] == :list
              email.from = options[:from] if options[:from]
              
              case options[:subject_prefix]
              when :list_name
                email.subject = "[#{list.downcase}] #{email.subject}" unless email.subject =~ /\[#{list}\]/i
              when false, nil
                # do nothing
              else
                email.subject = "[#{options[:subject_prefix]}] #{email.subject}" unless email.subject =~ /\[#{options[:subject_prefix]}\]/i
              end
              

              ActionMailer::Base.deliver(email)
            end
          end
        end
      end
    end
    
  end

  ActiveRecord::Base.send(:include, DL::Fughley)