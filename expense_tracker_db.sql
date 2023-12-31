PGDMP     ;        	            {            expense_tracker_db    15.3    15.3 4    +           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            ,           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            -           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            .           1262    17221    expense_tracker_db    DATABASE     �   CREATE DATABASE expense_tracker_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
 "   DROP DATABASE expense_tracker_db;
                postgres    false            �            1255    17400    check_budget_threshold()    FUNCTION     �  CREATE FUNCTION public.check_budget_threshold() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DECLARE
        v_budget INTEGER;
        v_budget_threshold INTEGER;
        v_amount_within_month INTEGER;
    BEGIN
        -- Get the budget and budget threshold for the category
        SELECT amount, budget_threshold INTO v_budget, v_budget_threshold
        FROM public.budget
        WHERE category_id = NEW.category_id AND user_id = NEW.user_id;

        -- Calculate the amount within the current month
        SELECT SUM(amount) INTO v_amount_within_month
        FROM public.transaction
        WHERE category_id = NEW.category_id AND user_id = NEW.user_id AND EXTRACT(YEAR FROM date) = EXTRACT(YEAR FROM NEW.date) AND EXTRACT(MONTH FROM date) = EXTRACT(MONTH FROM NEW.date);

        -- Check if the amount within the month exceeds the budget by the threshold
        IF v_amount_within_month > v_budget_threshold THEN
            -- Trigger a warning or notification here (e.g., raise an exception, log a message, send a notification, etc.)
            RAISE NOTICE 'Amount within the month exceeds the budget by the threshold.';
        END IF;

        RETURN NEW;
    END;
END;
$$;
 /   DROP FUNCTION public.check_budget_threshold();
       public          postgres    false            �            1255    17410 A   delete_transaction(character varying, character varying, integer)    FUNCTION        CREATE FUNCTION public.delete_transaction(p_user_name character varying, p_password character varying, p_transaction_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INTEGER;
    v_user_password CHARACTER VARYING(50);
BEGIN
    SELECT user_id, password INTO v_user_id, v_user_password
    FROM public."user"
    WHERE user_name = p_user_name;

    IF v_user_password = p_password THEN
        DELETE FROM public.transaction
        WHERE
            transaction_id = p_transaction_id
            AND user_id = v_user_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Transaction with ID % does not exist or does not belong to the user.', p_transaction_id;
        END IF;
    ELSE
        RAISE EXCEPTION 'Incorrect username or password.';
    END IF;
END;
$$;
 �   DROP FUNCTION public.delete_transaction(p_user_name character varying, p_password character varying, p_transaction_id integer);
       public          postgres    false            �            1255    17392 >   display_all_transactions(character varying, character varying)    FUNCTION     �  CREATE FUNCTION public.display_all_transactions(p_username character varying, p_password character varying) RETURNS TABLE(transaction_id integer, user_name character varying, date date, amount integer, category_name character varying, payment_method character varying, notes character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INTEGER;
    v_user_password CHARACTER VARYING(50);
BEGIN
    SELECT k.user_id, k.password INTO v_user_id, v_user_password
    FROM public."user" AS k 
    WHERE k.user_name = p_username;
    
    IF v_user_password = p_password THEN
        RETURN QUERY
        SELECT
            t.transaction_id,
            k.user_name,
            t.date,
            t.amount,
            c.category_name,
            t.payment_method,
            t.notes
        FROM
            public.transaction AS t
        JOIN
            public."user" AS k ON t.user_id = k.user_id
        JOIN
            public.category AS c ON t.category_id = c.category_id
        WHERE
            t.user_id = v_user_id
        ORDER BY t.date ASC;
    ELSE
        RAISE EXCEPTION 'Incorrect password for user %.', p_username;
    END IF;
END;
$$;
 k   DROP FUNCTION public.display_all_transactions(p_username character varying, p_password character varying);
       public          postgres    false            �            1255    17404 V   display_all_transactions_month(character varying, character varying, integer, integer)    FUNCTION     �  CREATE FUNCTION public.display_all_transactions_month(p_user_name character varying, p_password character varying, p_year integer, p_month integer) RETURNS TABLE(transaction_id integer, user_name character varying, date date, amount integer, category_name character varying, payment_method character varying, notes character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    DECLARE
        v_user_id INTEGER;
    BEGIN
        -- Validate user name and password
        SELECT k.user_id INTO v_user_id
        FROM public."user" AS k
        WHERE k.user_name = p_user_name AND k.password = p_password;
        
        IF v_user_id IS NULL THEN
            RAISE EXCEPTION 'Invalid username or password.';
        END IF;
        
        -- Return transactions within the specified month and year
        RETURN QUERY
        SELECT t.transaction_id, u.user_name, t.date, t.amount, c.category_name, t.payment_method, t.notes
        FROM public.transaction AS t
        JOIN public."user" AS u ON t.user_id = u.user_id
        JOIN public.category AS c ON t.category_id = c.category_id
        WHERE t.user_id = v_user_id
        AND EXTRACT(YEAR FROM t.date) = p_year
        AND EXTRACT(MONTH FROM t.date) = p_month
		ORDER BY t.date ASC;
    END;
END;
$$;
 �   DROP FUNCTION public.display_all_transactions_month(p_user_name character varying, p_password character varying, p_year integer, p_month integer);
       public          postgres    false            �            1255    17396 :   display_category_sum(character varying, character varying)    FUNCTION     z  CREATE FUNCTION public.display_category_sum(p_user_name character varying, p_password character varying) RETURNS TABLE(category_name character varying, total_amount integer, budget integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INTEGER;
BEGIN
    SELECT user_id INTO v_user_id
    FROM public."user"
    WHERE user_name = p_user_name AND password = p_password;

    IF v_user_id IS NOT NULL THEN
        RETURN QUERY
        SELECT c.category_name, SUM(t.amount)::INTEGER AS total_amount, b.amount AS budget
        FROM public.transaction AS t
        JOIN public.category AS c ON t.category_id = c.category_id
        LEFT JOIN public.budget AS b ON t.category_id = b.category_id AND t.user_id = b.user_id
        WHERE t.user_id = v_user_id
        GROUP BY c.category_name, b.amount;
    ELSE
        RAISE EXCEPTION 'Invalid username or password.';
    END IF;
END;
$$;
 h   DROP FUNCTION public.display_category_sum(p_user_name character varying, p_password character varying);
       public          postgres    false            �            1255    17399 R   display_category_sum_month(character varying, character varying, integer, integer)    FUNCTION       CREATE FUNCTION public.display_category_sum_month(p_user_name character varying, p_password character varying, p_year integer, p_month integer) RETURNS TABLE(category_name character varying, total_amount_within_month integer, budget integer, budget_threshold integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INTEGER;
BEGIN
    -- Validate user name and password
    SELECT k.user_id INTO v_user_id
    FROM public."user" AS k
    WHERE k.user_name = p_user_name AND k.password = p_password;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid username or password.';
    END IF;

    -- Calculate the total amount within the specified month and retrieve the budget and budget threshold for each category
    RETURN QUERY
    SELECT c.category_name,
           CAST(SUM(CASE WHEN EXTRACT(YEAR FROM t.date) = p_year AND EXTRACT(MONTH FROM t.date) = p_month THEN t.amount ELSE 0 END) AS INTEGER) AS total_amount_within_month,
           b.amount AS budget,
           b.budget_threshold
    FROM public.transaction AS t
    JOIN public.category AS c ON t.category_id = c.category_id
    LEFT JOIN public.budget AS b ON t.category_id = b.category_id AND t.user_id = b.user_id
    WHERE t.user_id = v_user_id
    GROUP BY c.category_name, b.amount, b.budget_threshold;
END;
$$;
 �   DROP FUNCTION public.display_category_sum_month(p_user_name character varying, p_password character varying, p_year integer, p_month integer);
       public          postgres    false            �            1255    17405 �   insert_transaction(character varying, character varying, date, integer, character varying, character varying, character varying)    FUNCTION     _  CREATE FUNCTION public.insert_transaction(p_user_name character varying, p_password character varying, p_date date, p_amount integer, p_category_name character varying, p_payment_method character varying, p_notes character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INTEGER;
    v_category_id INTEGER;
BEGIN
    -- Validate user name and password
    SELECT user_id INTO v_user_id
    FROM public."user"
    WHERE user_name = p_user_name AND password = p_password;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid username or password.';
    END IF;

    -- Retrieve the category_id based on the provided category_name
    SELECT category_id INTO v_category_id
    FROM public.category
    WHERE category_name = p_category_name;

    IF v_category_id IS NULL THEN
        RAISE EXCEPTION 'Invalid category name.';
    END IF;

    -- Insert the transaction into the transaction table
    INSERT INTO public.transaction (user_id, date, amount, category_id, payment_method, notes)
    VALUES (v_user_id, p_date, p_amount, v_category_id, p_payment_method, p_notes);
END;
$$;
 �   DROP FUNCTION public.insert_transaction(p_user_name character varying, p_password character varying, p_date date, p_amount integer, p_category_name character varying, p_payment_method character varying, p_notes character varying);
       public          postgres    false            �            1255    17398 [   update_budget_by_category(character varying, character varying, character varying, integer)    FUNCTION     [  CREATE FUNCTION public.update_budget_by_category(p_user_name character varying, p_password character varying, p_category_name character varying, p_new_budget integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DECLARE
        v_user_id INTEGER;
        v_category_id INTEGER;
    BEGIN
        -- Validate user name and password
        SELECT user_id INTO v_user_id
        FROM public."user"
        WHERE user_name = p_user_name AND password = p_password;
        
        IF v_user_id IS NULL THEN
            RAISE EXCEPTION 'Invalid username or password.';
        END IF;
        
        -- Get the category ID based on the category name
        SELECT category_id INTO v_category_id
        FROM public.category
        WHERE category_name = p_category_name;
        
        IF v_category_id IS NULL THEN
            RAISE EXCEPTION 'Category not found.';
        END IF;
        
        -- Update the budget for the specified user and category
        UPDATE public.budget
        SET amount = p_new_budget
        WHERE user_id = v_user_id AND category_id = v_category_id;
    END;
END;
$$;
 �   DROP FUNCTION public.update_budget_by_category(p_user_name character varying, p_password character varying, p_category_name character varying, p_new_budget integer);
       public          postgres    false            �            1255    17402    update_budget_threshold()    FUNCTION     �   CREATE FUNCTION public.update_budget_threshold() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.budget_threshold = NEW.amount * 1.1; -- Assuming 10% threshold
    RETURN NEW;
END;
$$;
 0   DROP FUNCTION public.update_budget_threshold();
       public          postgres    false            �            1255    17409 �   update_transaction(character varying, character varying, integer, date, integer, character varying, character varying, character varying)    FUNCTION     �  CREATE FUNCTION public.update_transaction(p_user_name character varying, p_password character varying, p_transaction_id integer, p_date date, p_amount integer, p_category_name character varying, p_payment_method character varying, p_notes character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INTEGER;
    v_category_id INTEGER;
BEGIN
    -- Validate user name and password
    SELECT user_id INTO v_user_id
    FROM public."user"
    WHERE user_name = p_user_name AND password = p_password;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid username or password.';
    END IF;

    -- Retrieve the category_id based on the provided category_name
    SELECT category_id INTO v_category_id
    FROM public.category
    WHERE category_name = p_category_name;

    IF v_category_id IS NULL THEN
        RAISE EXCEPTION 'Invalid category name.';
    END IF;

    -- Update the transaction in the transaction table
    UPDATE public.transaction
    SET date = p_date,
        amount = p_amount,
        category_id = v_category_id,
        payment_method = p_payment_method,
        notes = p_notes
    WHERE transaction_id = p_transaction_id
        AND user_id = v_user_id;
END;
$$;
   DROP FUNCTION public.update_transaction(p_user_name character varying, p_password character varying, p_transaction_id integer, p_date date, p_amount integer, p_category_name character varying, p_payment_method character varying, p_notes character varying);
       public          postgres    false            �            1259    17257    budget    TABLE     �   CREATE TABLE public.budget (
    user_id integer NOT NULL,
    category_id integer NOT NULL,
    amount integer,
    budget_threshold integer
);
    DROP TABLE public.budget;
       public         heap    postgres    false            �            1259    17256    budget_category_id_seq    SEQUENCE     �   CREATE SEQUENCE public.budget_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.budget_category_id_seq;
       public          postgres    false    222            /           0    0    budget_category_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.budget_category_id_seq OWNED BY public.budget.category_id;
          public          postgres    false    221            �            1259    17255    budget_user_id_seq    SEQUENCE     �   CREATE SEQUENCE public.budget_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.budget_user_id_seq;
       public          postgres    false    222            0           0    0    budget_user_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.budget_user_id_seq OWNED BY public.budget.user_id;
          public          postgres    false    220            �            1259    17242    category    TABLE     u   CREATE TABLE public.category (
    category_id integer NOT NULL,
    category_name character varying(50) NOT NULL
);
    DROP TABLE public.category;
       public         heap    postgres    false            �            1259    17241    category_category_id_seq    SEQUENCE     �   CREATE SEQUENCE public.category_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.category_category_id_seq;
       public          postgres    false    217            1           0    0    category_category_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.category_category_id_seq OWNED BY public.category.category_id;
          public          postgres    false    216            �            1259    17249    transaction    TABLE       CREATE TABLE public.transaction (
    transaction_id integer NOT NULL,
    user_id integer NOT NULL,
    date date NOT NULL,
    amount integer NOT NULL,
    category_id integer NOT NULL,
    payment_method character varying(50) NOT NULL,
    notes character varying(50)
);
    DROP TABLE public.transaction;
       public         heap    postgres    false            �            1259    17248    transaction_transaction_id_seq    SEQUENCE     �   CREATE SEQUENCE public.transaction_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.transaction_transaction_id_seq;
       public          postgres    false    219            2           0    0    transaction_transaction_id_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.transaction_transaction_id_seq OWNED BY public.transaction.transaction_id;
          public          postgres    false    218            �            1259    17235    user    TABLE     �   CREATE TABLE public."user" (
    user_id integer NOT NULL,
    user_name character varying(50) NOT NULL,
    password character varying(50) NOT NULL
);
    DROP TABLE public."user";
       public         heap    postgres    false            �            1259    17234    user_user_id_seq    SEQUENCE     �   CREATE SEQUENCE public.user_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.user_user_id_seq;
       public          postgres    false    215            3           0    0    user_user_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.user_user_id_seq OWNED BY public."user".user_id;
          public          postgres    false    214            �           2604    17260    budget user_id    DEFAULT     p   ALTER TABLE ONLY public.budget ALTER COLUMN user_id SET DEFAULT nextval('public.budget_user_id_seq'::regclass);
 =   ALTER TABLE public.budget ALTER COLUMN user_id DROP DEFAULT;
       public          postgres    false    222    220    222            �           2604    17261    budget category_id    DEFAULT     x   ALTER TABLE ONLY public.budget ALTER COLUMN category_id SET DEFAULT nextval('public.budget_category_id_seq'::regclass);
 A   ALTER TABLE public.budget ALTER COLUMN category_id DROP DEFAULT;
       public          postgres    false    221    222    222            �           2604    17245    category category_id    DEFAULT     |   ALTER TABLE ONLY public.category ALTER COLUMN category_id SET DEFAULT nextval('public.category_category_id_seq'::regclass);
 C   ALTER TABLE public.category ALTER COLUMN category_id DROP DEFAULT;
       public          postgres    false    216    217    217            �           2604    17252    transaction transaction_id    DEFAULT     �   ALTER TABLE ONLY public.transaction ALTER COLUMN transaction_id SET DEFAULT nextval('public.transaction_transaction_id_seq'::regclass);
 I   ALTER TABLE public.transaction ALTER COLUMN transaction_id DROP DEFAULT;
       public          postgres    false    218    219    219                       2604    17238    user user_id    DEFAULT     n   ALTER TABLE ONLY public."user" ALTER COLUMN user_id SET DEFAULT nextval('public.user_user_id_seq'::regclass);
 =   ALTER TABLE public."user" ALTER COLUMN user_id DROP DEFAULT;
       public          postgres    false    215    214    215            (          0    17257    budget 
   TABLE DATA           P   COPY public.budget (user_id, category_id, amount, budget_threshold) FROM stdin;
    public          postgres    false    222   Af       #          0    17242    category 
   TABLE DATA           >   COPY public.category (category_id, category_name) FROM stdin;
    public          postgres    false    217   |g       %          0    17249    transaction 
   TABLE DATA           p   COPY public.transaction (transaction_id, user_id, date, amount, category_id, payment_method, notes) FROM stdin;
    public          postgres    false    219   >h       !          0    17235    user 
   TABLE DATA           >   COPY public."user" (user_id, user_name, password) FROM stdin;
    public          postgres    false    215   u�       4           0    0    budget_category_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.budget_category_id_seq', 1, false);
          public          postgres    false    221            5           0    0    budget_user_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.budget_user_id_seq', 1, false);
          public          postgres    false    220            6           0    0    category_category_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.category_category_id_seq', 15, true);
          public          postgres    false    216            7           0    0    transaction_transaction_id_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.transaction_transaction_id_seq', 1002, true);
          public          postgres    false    218            8           0    0    user_user_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.user_user_id_seq', 3, true);
          public          postgres    false    214            �           2606    17263    budget budget_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_pkey PRIMARY KEY (user_id, category_id);
 <   ALTER TABLE ONLY public.budget DROP CONSTRAINT budget_pkey;
       public            postgres    false    222    222            �           2606    17247    category category_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (category_id);
 @   ALTER TABLE ONLY public.category DROP CONSTRAINT category_pkey;
       public            postgres    false    217            �           2606    17254    transaction transaction_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (transaction_id);
 F   ALTER TABLE ONLY public.transaction DROP CONSTRAINT transaction_pkey;
       public            postgres    false    219            �           2606    17240    user user_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (user_id);
 :   ALTER TABLE ONLY public."user" DROP CONSTRAINT user_pkey;
       public            postgres    false    215            �           2620    17401     transaction check_budget_trigger    TRIGGER     �   CREATE TRIGGER check_budget_trigger AFTER INSERT OR UPDATE ON public.transaction FOR EACH ROW EXECUTE FUNCTION public.check_budget_threshold();
 9   DROP TRIGGER check_budget_trigger ON public.transaction;
       public          postgres    false    239    219            �           2620    17403 &   budget update_budget_threshold_trigger    TRIGGER     �   CREATE TRIGGER update_budget_threshold_trigger BEFORE UPDATE ON public.budget FOR EACH ROW EXECUTE FUNCTION public.update_budget_threshold();
 ?   DROP TRIGGER update_budget_threshold_trigger ON public.budget;
       public          postgres    false    222    224            �           2606    17279    budget budget_category_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.category(category_id) NOT VALID;
 H   ALTER TABLE ONLY public.budget DROP CONSTRAINT budget_category_id_fkey;
       public          postgres    false    217    3207    222            �           2606    17274    budget budget_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(user_id) NOT VALID;
 D   ALTER TABLE ONLY public.budget DROP CONSTRAINT budget_user_id_fkey;
       public          postgres    false    222    3205    215            �           2606    17269 (   transaction transaction_category_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.category(category_id) NOT VALID;
 R   ALTER TABLE ONLY public.transaction DROP CONSTRAINT transaction_category_id_fkey;
       public          postgres    false    219    3207    217            �           2606    17264 $   transaction transaction_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(user_id) NOT VALID;
 N   ALTER TABLE ONLY public.transaction DROP CONSTRAINT transaction_user_id_fkey;
       public          postgres    false    219    215    3205            (   +  x�M��� 1ߞ`���l�q�����T	�ȳ�/���'�;O�>���K��Y�"���&���� �E��S"�D��{'DJ���KdHm���"��R��<[��"Sc����"��v��,�.s^��~�����T��D�T������p1�Rs��\4FK��Y�9̂�H)��C��'.�"�$�$ȅ�+�Mh���nZ�9v�h�ٿ�?��O��W�>m�����{��H�xΒ���� S�LE�I��t���]v����]�@�!�q`��.�G�,��4N_<-yO���8�>�����}�Ye�      #   �   x�%���0�g�)�@��ܢ@6�PL��:(q�x{u��w�3��R`�XB����Aq�`%~|P��pSv��\D��dv�#\�N���'�9�%�ؓu�.*��{���̠r^ߩ��3��ź4%4��8����f{�SqLJb�M��0K�������	"�&&G�      %      x�u�I�-�m��'W�\;tci�x"Y
[9B��C?�u+&jpz�eeC� >t��m�_��j��������_���?�������?��_�ø�￯��#��n^��~�����������/X��}A�S?��s]��_��_C>��Y�?��/�I|q�������%߯"��}���z���=�x�����X�)
���>Â_1,�_���6�Q�������H㻆}����=�՟��W�1�.�� ���	������#��o��D����ޯ�W����?Qt]�.��k�*��^zu���t�M\�3깙]��k��#Ӓ F��# ����ǽ�o�F���ßGm��:0���c���~������涎��+,-|nWK�k�5�[�c˺���|A�{���$�0o��Dn�Q�+\z����ڿ�31vbiM��!cЇ����.��#<����Kt�k���W�j�qs\P8�
� ��}#^�2�7|��$^�[�\�y�E7�v�tM������|Mㄩ3#��O�k~k\��(M����t�D|��oڅ��>��ʳ]�0&��~⻯~�8������q���!̮��2�5�4p��X\�X��+hQ_�|����Z�o�%K}��kq|y�@��+_��kI��e�v<V��������.�kY�~�A�����Z�@����W�~Q�#��ǝ_I�ֽ/Ҥh^4����=�RZ}�����/F���>P�6�o����"�W�����H.���־�{j�^�a>��j����,��;}h���]�,wɢ�~q3����x\<➂1�j��y�b��PL�.^�Uҏk�b

�߾�EͰd8���t��b	��g����ŚM���]��]l�r�����r�vI[^��%!��gO�:�I�%#L��!���9�2/����{.���KV��K��]��x�m^J^���m5LR�"�A�O�K�~�U?��Aۥ-�b0+N����T��nX���q鈳�������w������^]$��K)����T���V� ��*F�R���Qϳ]a�k0��}fy2�]j����6Q6�.ka���������z4��P�d�ظ,Z*��:fGRC6/K��5�!K�Y��8C1]����˾��۪��_�˾7JL;���F5�L�V��jy�^7H,���y�H��9
�L,�ޜ�Z\x�b�P�zSX�
m܋=�7�Qa��xh�ހDmƙsK��E����E�n���~�lԢB�C�Z���qP~���Fz'5	Ȭ�}�J-��u�i�Vj���>�9������m�ƫU{X6��o�nN�=���cV�vZ�qGu#D��莫=L�e�;��d�`�i�x�;����|���~�����07���,nuskCx�!dѣ,�'��/ ��#��γ��J�����+�`�d\�:�z�M�Tlm�G�UX��_�!��
/�-o���<���t;8�������y�_�K{�e�а��4d�0���1,�jIj�����P�҆��/�������|:��8xآ`����{rf�d,7V����y"�dH5�`\����B&��Fu� "M .~q3��S��_�z�=O�m�i˞{�K7���n,ض���� ]��=�y�ť�Ŋz
�]/�z���.����{�En�-�~���+�԰fL�;a��;��u�����������5:��� Q�.K o_�������������������W�s��-�A#�\lDt�30p��`�c��\�(L��+ó�{:)(f��@��=	���P�*�-��Ý$�?\������=��q�k.7U@q��6����u`1~���67�� w�Yg�@+o2иs�{5g&�,�/Bl�Y��+��o���4e�ǝ��.�����t��a䀔{@��o�ʺ0I@�= ��s�h�#�29w��
�:��lf�p�w�¶>w���;��|:��6��L�\V��(��62�a���{��mN�Z�H�K��JD�_����+�����ߐ�MQ��B<�Hؽ�i���C�Ny��uG0x�乆}騕�-`x������������r�|�(��r�UK8�_T�.�X�ۤ�<�S�����"��c��w��Tg�#n��C67�t;<�\�a���C_o:�׊�3��G �{��;*��'6 ��qO��8�zH�M�M;:��r���<���Eq-c���Km�6�w�h����A�w��^�o{��#$d��t�f[/g�yp�w��]�2�F�(۳�L�7=S|� ӏ�D�N������,u�d� =~a��jt��Q`�_���]%�����)�iB�s,�_ty�v��u �G���ܺq��fz9B�������	�9�� ~<A�;B�:ݩ{�3śݱ��Z`����s�!��}���#4��{��G_�J��mz�h~�h�5�:F֣ؔ�8~����� ��L�>�Q��!����h�w��=n���W��C�#�-;�����УG×�dN���q#�bp����c�c������{zD��z�� ^��r��:ox$:����pޡ��X@��`��3<��7l:ׄǣ��ǻ�,]x3-
w�TF� ��'(}���#b9 �����&H�iz�#�[;�Y�{�>�
��J��qF�F ��_+���܎_�)8�*�w��I�o_Iv���o(a�y���r���xH߭����6-�;7E�mk������Sm���_�~_��O��?��_{i��f���P�W�q^�˳9����T� ���gϺ���c�R��Ƹ$q���n�e�w�JE/Hh�@ ��J?�S �ea�Bw-;�c���h~ؗ��F����;ܻ���RH���,.+�	�t(�9����!%_ ��ڱ5�'�Ĉ�O��/�T�Üp�';1��H8��e���/��o�C� �� ��Q<q�w_��.��w�tY���#���ڑ(2�������<��#�>~qcƙ�¸s�j�^A�����C)P2Ԩԫ����]<'��� ��)ԅ/���~�4,���?7�i�~�9� �/#�|)v8Ȉ&�G F�Ҁ�����t7W�ť���,4��O�
�?$y+�kܪ�� ��wؼ��x�'�I���Y\e;0�'�����C������i���j� ���[,a�^��<���EV95��#��w�Zg�u3@���;���
��V[�+_������l������5!'M�̼Q �h����ɝյ�A�yF{0��B
iiZHX��ۤRJN O�������u�� ��'B+��[�4����[��]�ׅq�wȿ�����8;�R������L���-���Z���`����a��iyA��H��ͳ:���q�bqMP>~1j���*M�	Ο-	��w��≋gt�q漩N��l�ky�)����b,��v��})_�ň�S�������bf�GNM�4���E��g��k���"V4���A��Ǽ,������n{��|�-q�g���`)�	ꟁ����,V����o����o����<|��J�a��fv �,���Lr 8=Wf���� �!{�Lq�	�����
�*����9���ƙ8��#j�q�S��=¬��oe�p����9��B&#&�8P�\,1�1R�Ho��Èr�Y��y��Y�O�:{f�c$�2�P���Ԑb;vĤ����u�kV��'�Ϟ/��I���D���>����;S=�4mf�sԃ`�5��*^2I���`f�Xb�_��
HdF�_`�oQ̸�xB+ԝ��8�p���V|?W��N>r�����[w���,s�A�3E󿌛�" "	t�]4��(�\^=���r?�g��%��+���ϫ ���Ǟ6>��y�g�����B�����<r���g�{|rda�'�����^�㗽k4f��l?)r�[}�HT��ޮM��*��:�!    ��>%m��0	"�X���]9?�+@��zA�rwM��#`/�EPO��8+=���&A~tl;�}U�R���w��$j��, ��b�0��1A�����t`��cLf޵�]�}�c2X�2�͓!Nޘ�sn�n`Ȃ_k��5٫r�����ːG��7�z�1���<�i��8��ó���-i���.�q�U!�4R���P�E1S �'�vI,+��S ������r�H��s�V�Z ��!���G�Y����V�Ê����3����7���]cI��N��$�6���+��X!���1*�2�3�
���c�F\� ��4�����>S!��!��&;��BP�pǃnT�T!)M�M(�^&�L��4%��ҥm�կ��侎�l��i��=f�-����t/*YG
�4'��� �I� ���w��Z,^iXZ;�f|��9XRh�V9�A��&l�� 9�����c4H�8�E� ����.)�� �k�ML�c���0�^�-��t5�7�
��&{����q鳽�~�����k�F�8����ڼVK�gl����-\zTb��_J�������*.e\z�5}����H./	V=vC9S/���Y,�30u����ud�xz��h�J�\��BS�s�e�guH'x�]�R���!�P�.ny�1I�C<}en{���L����
!vH�G�&�[��1�d����6�VW��zJ��:RV���S`��]��ր�F2`s��jh�&d�	��+n襻1��ig��Θ/��_�i�`,WY���r�'��ׂie���|���8�i �k9��2gcH'��;���u���H�vk���ˌ��봕�{քXfDҍe��Md��Q��|<�˩�U�-��5!��j�`��5!���	�Ǿ�&����'�]a�VބB���J:G��x\�xpu �&d0c��59[gy){�
���X-�h_���֙����=T���;�-/n_3nU�!,�.l���z��F^���wq.�[�׷�h��~�d���+�%A���k�W̑u�q;�����8����\��Pra��K��a��zuQ�W� �����^Պ/�L(�������lB��i�{X\��"������ �����Z�O����.㵃|T�/����\�f�Ɉ��ބ`bxx�Y�����M��E=յ��0-v��,I�~-���n�r���x�C,Z+=���8���=���k,����;���0Z��!R��W���!�P`;�]�4����wL{�tq[�c���/U��,��׎�%U���i�xa�^+T�=?����_��17�9o��M���p=P�B,`���f�y:��u/���XL6�v	%�/޵#���m��xA�#��H���G�;M�L�[@}�"���·���+���Ym~�����X��ދ��_��]-kp�
���V>�M�JY �1링�_��}Ke����=�<s;���L%�����+, �R���}p?��TY�/���W�?#�(9�b�L&hY=zu, ���k��ǎ��_W�3EPp�,n);���4X��e������{7����l� �W�z���1�h߫Nw��˳޼�M˻�ԥ����k��s����o7Y������dwH�������o#������.
���6Hs�2��E-j+Oy�u|�࢔O�?wa�{(����y��<�����;�p������V��O�fCQMy?��%p<���)�U����b<�Џ������+jh�z�ܛ���S�
|�Q���G�����]�}1��ST3r��m���V���/�����֞d�:$�=����Ȝ�I�[Bŭ��j��)��۪�K^���F�V�GёKD�zqO��z����F�a��z�\���HN1�G�{)�i��σˉ��� �<9����f�kވ���# >�$W,E4���4�n�<s4��w�J	}��zɌu~��bG=��)����g)'(��o߰������`F���D�x͸�x��a��<����%�ה�0���j��)���9`�P����;�`2��(ާ��n�Li�2���wUKEd�}ɕ��Ӣ���ݦ�Y�؍ #���x���j9��	M����-s�O��-๎����ņ=������vO�Ym��[A�vL�yu����}��Fys����oU�#��vvL'V�0�����ևƳ�����$@��RZ,椔�=�By���1��n$�a{��@�ĩ�b�4�����߿լ��J�S���ַZ7��R�?~V���{T�4���� G��\ 5�z�؏�#�艣��ME-�	@O��`����� y�Ý^��.�$�\ �ŕw���$������C�zJ��|h+u1���|�;��$i��I(���r֓�Fc��i�%�R������� "�y0�T�(����,y���5��� ����u���)���}=��T, |�俜߽R��=�)	Ho�LspO!�/��zqH�݀{
(��J�Q��H��f����B��a���8�&�Ł�a�����Ë,毸e�sl�@�R�]�CJu>'�:��}�������ڪ&T'��y������N!��z+��`'K���1�t��,�
��[vJ5��0W��>n���y�a�j�2��[^��s$32��[ܰ}V���)ÿ;Q�S?|������-�T�s��_^�u�y?�/n1��z��<<rq���|��F/nqgp/���"����1=�]W*��9P�m���k�������g\�x�{%z`�Ȫc�:����`����!��SG����A-H�;s���B��H��g��*��ǊHWI��/��oͬ��&�4ϝ^�� 4�)��hNT���9���]#���<����^�}���[��X��8t�۱k��(���:����iٸa�7
ݣ
��}a 8 wK�uLR�7�X��V&40�S9��NQ�:� p��H����������\������9�윙�C��f�1����|+� q����u`o��L?w��})�1#P��]ˮg �/&λeaH#���1oEVlF���R�l�D��o^�C��e�J<f�7���A]�2țC�ݸ�0!��}�=�n��}�7�^�R�7�O�xVl���^�h�Ġn^1X��n�(���k{����yE��k����7rߣ�0�����<U������^�e������R3�qw��WA��Ե�|�g���J�w�'/v/,��I�_zh-�7��YUw w3�l�nMy1��R,���o3	u�C�u���O��!k)�1�-�9�r�إ
��7��he��r���2Jv��Zg�yo<�0�;c�n-�&�w���m��R�w�yK����@`�=B�;yi�*ػ�?�wS���
����}���b�6K���G�T�N��!x��N�i���)���T����y@�h���ʑ� m�m����4`i���:��u���
��Og���2IN`�s $�>���iփ�Yb����eV��Y,ov�λa�6k�*pw&=��B����Zc 6����v��k��=�w^~(�1i��d��X4.�z�E�Ewq.��<�#��
�h�O������ĝ�ϸ1���5��`cm3���{����@u��7=iY�� vm��ת�`�P�E�)��bJ��tN]�<�8�X!V������׏m��#O��=��8�{2�*�Dl~^�E�]w/���Y����l_?U�8�p.�I������� �%��N ��p���x�n�Ϋ�%-%������� ɥ�^����t�X\Z�2�\���z �%d�o}jV��^���y�l�!�K�eCmԅ�B��ZI�}�[R����X��~�^&� ]B@�w=s�����Pߪ��U�
��#�ǃ}�4;p������ˌT�K���4�$W�`]z�� G6 ��u��+(Mj�����{;��X^ �2�a(n�Y�~S �2�Z�^�㰈��]���6�e�E��2����   ��\�+��;��t�]s=�WA#�����{�s�ː<���o�4F�R�}�C1��2���Vw�`���~<�ȁ)��L�%|T��v�9���ey�L?�'v��ڱyd(^��L/��L'�x������!����@���!�3�R����@D3�y�F_y��eZ6,|֥�n�p�ۭF�&�d����d�5����e�cB��\�ɑ��%ݬ�EY~0S<�`W���o��%����-��Gbv�����ĊY��KᴞԠv	�ay]�"�wY����=qvJi�s�Q�u���#�-����8���}X��� /�ߎ��5��R����);+�6�iY���uR���>]4l�#rt�u���ly���%T���@/S��<����y]�nY��ޓ�� �G'�7a���pt�x��K�@w	���ނ�er�T�sU��Y@����a�H���ҹq|���� ����s8/�9�6�n�. yo���YXW~���o�oW��qr���|�f�Q��R?|w�~���$v��ղT�?WNbv�㷕5����a˝5�O�K ����?\NR�u?{RK����$�
\&�H�R�]��P\ϋF�5�Ȯ;�K��6�<���NW8��h��h<������P^4m'�>^4U��O�� �$�����g�%d�}N_����ϩ��8� �%@��fj+P��s�|�e���p�gKڏa��(�^�������ŐT���}��t/������ҳ �|���a��C���� ��c�Aa��\	/.+��H_,7ݿ�F��4?�1u��]ʙ�o~�cDO��)
��S$v+������5������Fq�ĵ3�[T�YA��R�wqb�LU࿶�F�)��9���p���e�UGB���>��S�^�N��^�G+�_[l����I}(�_sQ��*�-M�~�f����s����5��Φʏ�4R@�Y{V9�
�מ��}O~(��S���#��.�z\'�[6#��=�0.�V����Ҟ��d],<�k�GGxȿg��5�k�7J>w��{�.f��8:�����=PʣT���w�{���#*/�$��E����w/�9���5�ƻx���|���N���C ��Ͻ{��*(_�1w�[�����u��Y�5+ _g�>[���	�����`��Zs�i�Qe����u� �˥��
�׀����㣠|����9�&
��t��'����"�#t�߇��(�^SF�k�^n�
��t���=�2�_A��b��O����r��J��}���R@��� �3��l|��O~6�;z��T�뢬�w�\5s����+�U�q 1`_�{�����A:+n�aˬ�2J��v��e+�_)��~*s��Fsiȓ�T�Z1��5���ҭ�d�+�������W�n��h�j���';S���&���CN˳��!��qQ��+ݎp�����2r��C�b�+E���������+∫`�\ʇ��w��Tk�(��;p��-�k�oi+w1�r���#�~�vqr�y.nU˩��o���~�Bm?2d�qIyi���B"z��AJ�̗R��8F,�o�����	Q}��!��H(4ǻ3]�[*���Fk�|G/��*�Q����h�>���9I*�'��*�D�`�2�.0ѥ��f�S�k1�%�۩d��c�%�-���]�я�a{���v�?7���59+�_��XS?x^Sb���d���S�}�R�8K�z�.}o(LGdR��|����y>4�����> �������~g�3v�B��n�����s�5B�[r���@z�m�m�K^.{0��a�u�ŵH`�~��-�H�Ք�5��L
�WK�od{6��B6�������BD���}�L��A�j�������!#�;���G�����R�.݇ҽ�����R��}0X���-r�i�3�wHo��u���Aŗ���{��a`�����[��Ӛ."\DyxrA��EV�>�,`6`�����js֚�������ٰ�W*��.k����-M�[�u��"-��[8��>�A'=��e��6ށ��M������bvw�xOD�[8�nǎ�n���/$ԣ��YԷ�bb��+}Dԓ/���RxZ�o��^��h�[O��<���ۈu�_'`0a�~���l�r�������~PoX�VP�B1�lԯS6�o!��{��<��oOT�^�=Z�n`}�����Y�����x��b�^6��ն����2�I�=���@�6���I0ZV`��f�}���C��/Km��qu�ۜYگ��П����ݦ��M!�U��w�)H`���|�^�2�ی�K��V���	IM����D?!�̓�v_5P�Q���3��
�Z���[%�gտ���B��^�ά�Z�jŚ����Zh��V�&�]TWM�Q�t���Ǖf�/�jE��1+�lmAB+�l�%��S[͊����톌A&+f��v3� ����ݡ��R�W��'�oO��Wۭy�`�B����ݝmߢ����~���ǂ�-�y?�*��Qt��T�C@|�/�JI��{�7J����t ����&ƹ����cVh�^L����}wJ����-%���5��W�����n�j�$�7^�h��ߠ��-�z���C�A��t�ZV��d�u�Ԁh�s�Һ����}|�`�I���U�����I��SO=#8	�n!^?o�M�����Cz�$	
Xnwo�_O,7`�I�f�M�Y7I���t��Gb��V��t����$�vO�v|+� )���3zbR]�:ֹ�b3�n��7�b�8�n��w�h+m3໥�o�+j1�i��G���-��wy������
S_�G>���M�%�;�+Map����>,Z���(��S� ��ty�����f�[�v�Y�*3�^�39~�N�u���5]	nFY��,C��\���4{}�:5��:�1��oK��y��܂@�f1���(���������L��uݯKau�49�#��?������cm���x��_�$����":�����?v���W������u��!      !   I   x�3�����s�O�,H,..�/J142�2��J�K��,��,NM.-J�rs�ff��4��q�V´p��qqq ��     